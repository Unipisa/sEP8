# Attribuzione

Questo branch contiene quanto prodotto da [Nicola Ramacciotti](https://github.com/nicorama06) nell'ambito della sua Tesi di Laurea in Ingegneria Informatica, dal titolo "*Design e implementazione di un ambiente di simulazione e testing in Verilog per il processore sEP8*".

# sEP8 - Simple Educational Processor 8 bit

Questo progetto propone una descrizione in verilog del processore didattico sEP8, presente in [questo](http://www.edizioniets.com/scheda.asp?n=9788846743114) libro.
<br>
L'obbiettivo principale di questo progetto è quello di realizzare un ambiente di simulazione che permetta di mostrare il comportamento del processore duranate l'esecuzione di un programma. 
<br>
## Feature implementate
* Reti combinatorie interne al processore
  - `valid_fetch`
  - `first_execution_state`
  - `jmp_condition`
  - `alu_result`
  - `alu_flag`
* Spazio di memoria
  - Memoria RAM (`module ROM`)
  - Memoria ROM (`module RAM`)
* Spazio di IO
  - Con sincronizzazione
    - Interfaccia di uscita ASCII ( `interfaccia stampa caratteri`)
  - Senza sincronizzazione
    - Interfaccia di uscita ASCII (`interfaccia stampa caratteri`)
* Generatore di clock
* Assemblatore
## Reti combinatorie interne al processore
Le reti combinatorie sono state realizzate in verilog tramite `function`. Le function prendono parametri diversi a seconda dello scopo della rete, ma si basano tutte su un casex sull'opcode dell'istruzione:
<br>
* `valid_fetch` prende in ingresso un byte che interpreta come opcode e restituisce 1 se è relativo ad una istruzione nota, 0 altrimenti.
* `first_execution_state` prende in ingresso un byte, interpretato come opcode di istruzione nota, e restituisce la codifica del primo stato interno dell'esecuzione dell'istruzione relativa.
* `jmp_condition` prende in ingresso due byte, il contenuto del registro OPCODE e del registro dei flag. A seconda della codifica contenuto e del contenuto dei flag restituisce 1 se si sono verificate le condizioni per il salto, 0 altrimenti.
* `alu_result` serve per simulare la ALU interna del processore. Prende in ingresso 3 byte, interpretati come opcode,operando sorgente e operando destinatario, e restituisce il risultato su 1 byte coerentemente con l'operazione selezionata.
* `alu_flag` prende gli stessi ingressi di alu_result e restituisce sempre 1 byte, di cui 4 bit significativi, che rappresentano il contenuto dei flag significativi aggiornati in base all'operazione selezionata.
## Spazio di memoria
Modulo che rappresenta lo spazio di memoria a cui il processore può accedere ed è implementato tramite moduli RAM e ROM, selezionabili uno alla volta grazie ad una rete combinatoria che si basa sulla parte più significativa dei fili di indirizzo.
* La memoria RAM simula il comportamento di una memoria RAM
* La memoria ROM contiene il programma di avvio
## Spazio di IO
Lo spazio di IO qui presente ha una realizzazione con sincronizzazione e una senza
* L'interfaccia ha lo scopo di stampare come output di simulazione caratteri ascii
  - Senza sincronizzazine non c'è bisogno di leggere il registro di stato dell'interfaccia per mettere sul registro di uscita il carattere che si vuole stampare, con bisogna aspettare che il registro segnali che il buffer è vuoto
## Generatore di clock
* Modulo che serve per generare il segnale di clock necessario per il corretto funzionamento del sistema
## Assemblatore
* L'assemblatore qui proposto è una rivistazione di quello disponibile [qui](https://github.com/federicorossifr/sep8emulator).
* In particolare l'output dell'assemblatore fornisce un modulo ROM utile per la simulazione
* Ha delle limitazioni:
  - Non permette che ci siano righe vuote nel file.s
  - Non permette la dichiarazione di variabili.
  - Permette la presenza di etichette, che devono essere da sole sulla riga e si riferiscono all'istruzione della riga successiva e sono usabili in istruzioni di salto
  - le etichette possono essere usate solo se dichiarate nella parte di codice precedente, per salti all'indietro non in avanti
  - Gli operandi immediati e gli indirizzi devono essere passati in formato esadecimale e devono essere della dimensione corretta.
* Il comando da eseguire è: `python3 ./assembler.py file.s` e in uscita si ottiene `ROM_file.v`
  - NOTA: il comando va eseguito nella stessa directory di `file.s` e il nome del file non deve essere preceduto da `./` (da risolvere)
  - NOTA: `assembler.py` può trovarsi anche in una directory differente
* esempi del suo funzionamento sono nella cartella apposita

