# nmLab
 Repo per il laboratorio nanomateriali 2025.

# Assignments
## 1 ) Analisi dati lab in prosp. conf. beamtime 
-  Analizzare due spettri Ir-4f pulito. Calibrare lo spettro con livello di Fermi. Fittare con due picchi lo splitting spin orbita. 
Ricavare forma di riga: 
    1. Lorenziana
    2. Gaussiana
    3. Asimmetria
- Analisi spettro C1s sul campione Ir-4f. Fittare background con un polinomio di grado più basso possibile. Il grado del polinomio va bene quando il *residuo* del background è praticamente piatto.
Bisogna stare attenti di non fittare la coda destra del rumore perché, sebbene si alzi, questo è dovuto ad una differenza di efficienza di produrre / rilevare elettroni a quell'energia ma non rispetta il vero andamento del BG che dovrebbe essere una funzione monotona decrescente in questo caso.
Fatto questo si fitta il picco del C-1s con DS convoluto con una Gausssiana. 
- Analizzare le immagini LEED dell'iridio pulito e del grafene sull'iridio in modo da stimare la periodicità in spazio reale del reticolo di moiré e del carbonio. 

# LEED Imaging Software
- Software python per la correzione delle aberrazioni nelle immagini LEED e fitting degli spot di diffrazione. Realizzato con Tkinter.
  
https://github.com/user-attachments/assets/0aea8b1c-03c5-4b4d-a699-d3dae4394418

