`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company:       UPB
// Engineer:      Dan Dragomir
// Engineer:      Bogdan Badicu
//
// Create Date:   11:23:41 11/13/2015
// Design Name:   tester tema2
// Module Name:   tester
// Project Name:  tema2
// Target Device: ISim
// Tool versions: 14.7
// Description:   tester for homework 2: image processing
////////////////////////////////////////////////////////////////////////////////

module tester;

    parameter early_exit = 0;                   // boolean; bail on first error
    parameter show_output = 1;                  // boolean; show info
    parameter show_image = 0;                   // boolean; show image after transformation
    parameter max_errors = 32;	               // integer; maximum number of errors to show
    
    reg [16*8-1:0] test_name;
    real test_value;
    real test_penalty;
    integer test_type;                          // 0 - piecewise test, 1 - full test
    integer max_cycles;                         // maximum cycles to wait for a transformation
    
    integer config_file;
    initial begin
        config_file = $fopen("test.config", "r");
        if(!config_file) begin
            $write("error opening config file\n");
            $finish;
        end
        if($fscanf(config_file, "name=%16s\n", test_name) != 1) begin
            $write("error reading test name\n");
            $finish;
        end
        if($fscanf(config_file, "value=%f\n", test_value) != 1) begin
            $write("error reading test value\n");
            $finish;
        end
        if($fscanf(config_file, "penalty=%f\n", test_penalty) != 1) begin
            $write("error reading test penalty\n");
            $finish;
        end
        if($fscanf(config_file, "type=%d\n", test_type) != 1) begin
            $write("error reading test type\n");
            $finish;
        end
        if($fscanf(config_file, "max_cycles=%d\n", max_cycles) != 1) begin
            $write("error reading allowed maximum cycles for a transformation\n");
            $finish;
        end
        $fclose(config_file);
    end

    // Instantiate the Unit Under Test (UUT)
    wire      tst_clk, tst_img_clk;
    wire[5:0] tst_row, tst_img_row;
    wire[5:0] tst_col, tst_img_col;
    wire      tst_we;
    wire      tst_img_we;
    wire[23:0]tst_in_pix, tst_img_in_pix;
    wire[23:0]tst_out_pix, tst_img_out_pix;
    wire[2:0] tst_done;                         // (0-mirror, 1-gray, 2-filter)
    image #(.init(1)) tst_img(
        .clk(tst_img_clk),
        .row(tst_img_row),
        .col(tst_img_col),
        .we(tst_img_we),
        .in(tst_img_in_pix),
        .out(tst_img_out_pix));
    process tst_process(
        .clk(tst_clk),
        .in_pix(tst_in_pix),
        .row(tst_row),
        .col(tst_col),
        .out_we(tst_we),
        .out_pix(tst_out_pix),
        .mirror_done(tst_done[0]),
        .gray_done(tst_done[1]),
        .filter_done(tst_done[2]));

    // Instantiate reference implementation
    wire      ref_clk, ref_img_clk;
    wire[5:0] ref_row, ref_img_row;
    wire[5:0] ref_col, ref_img_col;
    wire      ref_we;
    wire      ref_img_we;
    wire[23:0]ref_in_pix, ref_img_in_pix;
    wire[23:0]ref_out_pix, ref_img_out_pix;
    wire[2:0] ref_done;                         // (0-mirror, 1-gray, 2-filter)
    image #(.init(1)) ref_img(
        .clk(ref_img_clk),
        .row(ref_img_row),
        .col(ref_img_col),
        .we(ref_img_we),
        .in(ref_img_in_pix),
        .out(ref_img_out_pix));
    ref_process ref_process(
        .clk(ref_clk),
        .in_pix(ref_in_pix),
        .row(ref_row),
        .col(ref_col),
        .out_we(ref_we),
        .out_pix(ref_out_pix),
        .mirror_done(ref_done[0]),
        .gray_done(ref_done[1]),
        .filter_done(ref_done[2]));

    // Tester
    reg clk;                                    // master clock
    
    reg[11:0] pix;                              // pixel being checked
    wire[5:0] row;                              // row being checked
    wire[5:0] col;                              // column being checked
    
    reg[2:0] tst_prev_done;                     // previous value of tst_*_done (0-mirror, 1-gray, 2-filter)
    reg[2:0] ref_prev_done;                     // previous value of ref_*_done (0-mirror, 1-gray, 2-filter)
    reg tst_finished;                           // true if tst finished
    reg ref_finished;                           // true if ref finished
    
    integer state;                              // tester FSM state
    `define START       0                       // prepare for transformation
    `define RUN         1                       // run transformation
    `define CHECK       2                       // check transformation
    `define RESULT      3                       // write results
    `define RESTORE     4                       // change tst image to known good state
    integer transf;                             // transformation number
    `define MIRROR      0
    `define GRAY        1
    `define FILTER      2
    
    reg[10*8-1 : 0] transf_name[2:0];           // transformation name as string
    initial begin
        transf_name[`MIRROR] = "mirror";
        transf_name[`GRAY] = "grayscale";
        transf_name[`FILTER] = "sharpen";
    end
    
    integer transf_ok;                          // true if current transformation is correct
    integer transf_cycles;                      // cycles used by tst for current transformation
    
    integer transf_passed;                      // weighted score passed
    integer transf_total[2:0];                  // weighted score total
    integer transf_good_pix;                    // number of good pixels
    integer transf_bad_pix;                     // number of bad pixels
    integer transf_total_pix = 64*64;           // total pixels checked
    
    reg [12:0] disp_transf_good_pix;            // appropiate size to print transf_good_pix
    reg [12:0] disp_transf_total_pix;           // appropiate size to print transf_total_pix
    
    real result;                                // test passed percentage
    integer file;                               // results file

    initial begin
        // initialize inputs
        transf_total[`MIRROR] = 100 * (2 * 64) + 125 * (4 * 64) + 5 * (58 * 64);
        transf_total[`GRAY] = 1 * (64 * 64);
        transf_total[`FILTER] = 198 * (4 * 63) + 13 * (62 * 62);
        
        clk = 0;
        state = `START;
        transf = `MIRROR;
        tst_finished = 0;
        ref_finished = 0;
        
        // clear results file
        file = $fopen("result.tester", "w");
        $fclose(file);
    end

    always #5 clk = !clk;
    
    assign row = pix[11:6];
    assign col = pix[ 5:0];
    
    // in the RUN state process and image clocks are active until the transformation is computed
    assign tst_clk = (state == `RUN && !tst_finished) ? clk : 0;
    assign ref_clk = (state == `RUN && !ref_finished) ? clk : 0;
    
    // in the CHECK and RESTORE states image clock is controlled by tester
    assign tst_img_clk = (state == `CHECK || state == `RESTORE) ? clk : tst_clk;
    assign ref_img_clk = (state == `CHECK || state == `RESTORE) ? clk : ref_clk;
    
    // in the CHECK and RESTORE states imgage row is controlled by tester
    assign tst_img_row = (state == `CHECK || state == `RESTORE) ? row : tst_row;
    assign ref_img_row = (state == `CHECK || state == `RESTORE) ? row : ref_row;
    
    // in the CHECK and RESTORE states imgage col is controlled by tester
    assign tst_img_col = (state == `CHECK || state == `RESTORE) ? col : tst_col;
    assign ref_img_col = (state == `CHECK || state == `RESTORE) ? col : ref_col;
    
    // in the RESTORE state tst image in_pix is controlled by tester
    assign tst_img_in_pix = (state == `RESTORE) ? ref_img_out_pix : tst_out_pix;
    
    // ref image in_pix always comes from ref process
    assign ref_img_in_pix = ref_out_pix;
    
    // in the states other than RUN tst process in_pix is tied to a constant value
    assign tst_in_pix = (state == `RUN) ? tst_img_out_pix : 24'b0;
    
    // ref process in_pix always comes from ref image
    assign ref_in_pix = ref_img_out_pix;
    
    // in the CHECK and RESTORE states image we is controlled by tester
    assign tst_img_we = state == `CHECK ? 1'b0 : (state == `RESTORE ? 1'b1 : tst_we);
    assign ref_img_we = state == `CHECK ? 1'b0 : (state == `RESTORE ? 1'b0 : ref_we);
    
    always @(posedge clk) begin                        
        tst_prev_done <= tst_done;
        ref_prev_done <= ref_done;
        
        case(state)
            `START: begin
                if(transf == `MIRROR || test_type == 0)
                    $write("--------------------------------------------------------------------------------\n");
                
                transf_ok <= 1;                     // assume transformation will be ok
                transf_cycles <= 1;                 // first cycle is always used
                
                tst_finished <= 0;
                ref_finished <= 0;
                
                transf_passed <= 0;
                transf_good_pix <= 0;
                transf_bad_pix <= 0;
                
                $write("test %0s - %0s", test_name, transf_name[transf]);
                
                state <= `RUN;
            end
            
            `RUN: begin
                // positive edge of done
                tst_finished <= tst_finished || ((tst_prev_done[transf] === 0) && (tst_done[transf] === 1));    // uut might generate "x"
                ref_finished <= ref_finished || ((ref_prev_done[transf] === 0) && (ref_done[transf] === 1));

                if(!tst_finished) begin
                    // tst is not done yet
                    transf_cycles <= transf_cycles + 1;
                end
                
                if(tst_finished && ref_finished) begin
                    if(show_output)
                        $write(" transformation done in %0d cycles\n", transf_cycles);
                    else
                        $write("\n");
                    
                    pix <= 0;
                    
                    if(test_type == 0 || transf == `FILTER)
                        state <= `CHECK;
                    else begin
                        state <= `START;
                        transf <= transf + 1;
                    end
                end
                else begin
                    // kill it if it's stuck
                    if(transf_cycles >= max_cycles) begin
                        $write("\n");
                        $write("\ttimeout after %0d cycles\n", transf_cycles);
                        
                        transf_ok <= 0;

                        pix <= 0;
                        
                        if(test_type == 0 || transf == `FILTER)
                            state <= `RESULT;
                        else begin
                            state <= `START;
                            transf <= transf + 1;
                        end
                    end
                end
            end
            
            `CHECK: begin
                if(pix == 0)
                    $write("--------------------------------------------------------------------------------\n");
                
                if(tst_img_out_pix === ref_img_out_pix) begin
                    transf_good_pix <= transf_good_pix + 1;
                    
                    case(transf)
                        `MIRROR: begin
                            if(row == 0 || row == 63)
                                transf_passed = transf_passed + 100;
                             else if(30 <= row && row <= 33)
                                transf_passed = transf_passed + 125;
                             else
                                transf_passed = transf_passed + 5;
                        end
                        `GRAY: begin
                            transf_passed = transf_passed + 1;
                        end
                        `FILTER: begin
                            if(row == 0 || row == 63 || col == 0 || col == 63)
                                transf_passed = transf_passed + 198;
                            else
                                transf_passed = transf_passed + 13;
                        end
                    endcase
                    
                    if(show_image) $write("\tchecking (%d, %d), found R:%d G:%d B:%d\n", row, col, tst_img_out_pix[23:16], tst_img_out_pix[15:8], tst_img_out_pix[7:0]);
                end
                else begin
                    if(transf_bad_pix <= max_errors || show_image) begin
                        $write("\terror at (%d, %d), found R:%d G:%d B:%d\n", row, col, tst_img_out_pix[23:16], tst_img_out_pix[15:8], tst_img_out_pix[7:0]);
                        $write("\t                expected R:%d G:%d B:%d\n", ref_img_out_pix[23:16], ref_img_out_pix[15:8], ref_img_out_pix[7:0]);
                    end
                    if(transf_bad_pix == max_errors) begin
						$write("\t.\n");
						$write("\t.\n");
						$write("\t.\n");
					end
                    
                    transf_ok <= 0;
                    transf_bad_pix <= transf_bad_pix + 1;
                    
                    if(early_exit) begin
                        state <= `RESULT;
                    end
                end
                
                pix <= pix + 1;
                
                if(pix == -12'b1) begin
                    state <= `RESULT;
                end
            end
            
            `RESULT: begin
                result = transf_passed * 1.0 / transf_total[transf];
                
                disp_transf_good_pix = transf_good_pix;
                disp_transf_total_pix = transf_total_pix;
                
                file = $fopen("result.tester", "a");
                $fwrite(file, "%5.2f: %d out of %d pixels (%6.2f%% completed) test %0s - %0s\n", test_value * (result - test_penalty), disp_transf_good_pix, disp_transf_total_pix, 100.0 * result, test_name, test_type ? "all" : transf_name[transf]);
                $fclose(file);
                
                if(transf < `FILTER)
                    if(test_type == 0)
                        state <= `RESTORE;
                    else begin
                        state <= `START;
                        transf <= transf + 1;
                    end
                else
                    $finish;
            end
            
            `RESTORE: begin
                pix <= pix + 1;
                
                if(pix == -12'b1) begin
                    state <= `START;
                    transf <= transf + 1;
                end
            end
        endcase
    end

endmodule
