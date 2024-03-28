Arhitectura Calculatoarelor
Tema 2: Procesare de imagine
Micu Ana-Mihaela
Grupa 331AB

Modulul "process" realizeaza procesarea imaginii prin trei operatii efectuate secvential: oglindire, grayscale și sharpness. Modulul primeste pixelii de intrare
dintr-o imagine, ii proceseaza pe baza operatiilor specificate si genereaza pixelii de iesire corespunzatori.

Pentru efectuarea celor 3 operatii sunt folosite 2 blocuri "always":

Partea secventiala: la fiecare front pozitiv de ceas, se schimba starea, linia, coloana iar în cazul filtrului de sharpness, se schimba si variabila în care se calculeaza
noua valoare a pixelului;
Partea combinationala: la fiecare schimbare a oricarui semnal din bloc, se identifica starea si se executa logica din cadrul acesteia.
Cele 3 operatii sunt realizate astfel:

Mirror:
Oglindirea incepe in starea 0.
Pentru oglindire, se realizeaza parcurgerea pixelilor din jumatatea superioara a matricei. Pentru fiecare dintre acesti pixeli se gaseste oglinditul din jumatatea
inferioara, iar apoi se realizeaza switch-ul dintre ei utilizand 2 variabile auxiliare: pixel_aux1 si pixel_aux2, in care pastrez valorile pixelilor.
Imaginea de intrare este oglindita secvential pe axa verticala pana cand intreaga imagine este procesata.
Operatia se finalizeaza cand toate randurile au fost oglindite, adica in starea 7.
Grayscale:
Grayscale incepe in starea 7.
Fiecare pixel este convertit folosind o medie aritmetica dintre valoarea maxima si valoarea minima a componentelor sale RGB. Aceasta operatie s-a realizat utilizand 3
variabile auxiliare: r, g și b, corelate cu cei 8 biți care reprezinta culoarea respectiva.
Operatia se finalizeaza cand toti pixelii au fost transformați, adica in starea 10.
Sharpness:
Sharpness incepe in starea 10.
Fiecare pixel este procesat in functie de vecinii sai utilizand matricea de convolutie [-1, -1, -1; -1, 9, -1; -1, -1, -1]. Pentru a realiza aceasta operatie presupunem
ca avem o matrice 3x3 pentru care notam pozitiile elementelor de la 1 la 9 astfel:
1 2 3
4 5 6
7 8 9

Pixelul de pe pozitia 5 este cel pe care il prelucram la un moment de timp. De exemplu, daca pixelul curent este pe pozitia (0,0) atunci vecinii lui vor fi pe pozitiile
8, 9 si 6. Vecinii pixelului sunt parcursi in sens trigonometric (3, 2, 1, 4, 7, 8, 9, 6).
Operatia se finalizeaza cand toti pixelii au fost filtrati (starea 26).

Procesarea pixelilor se realizeaza secvential, iar rezultatul este stocat in iesirea out_pix.
Pixelii procesati sunt scrisi in imaginea de iesire cand out_we este activat.