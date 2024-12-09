# RAG Data Engineering für arXiv-PDFs

Dieses Repository enthält den Programmentwurf und die Ausarbeitung.
Die Ausarbeitung ist als Typst-Datei im Ordner `ausarbeitung` verfügbar.

Der Programmentwurf besteht aus folgenden Dateien:

```
├── README.md
├── ausarbeitung  # Ausarbeitung als Typst-Projekt
├── arxiv_pdfs    # Eingabe-PDFs
│   ├── 2306.02088v2.pdf
│   ├── 2310.13425v1.pdf
│   ├── 2404.17008v2.pdf
│   ├── 2405.00695v1.pdf
│   └── ...    # weitere PDF-Dateien von arXiv
├── rag_import.py    # Skript zum Importieren der PDFs in die Vektordatenbank
├── rag_retrieval.py    # Skript zum Suchen nach ähnlichen PDFs
├── requirements.txt    # benötigte Python-Packages
└── test_pdfparse.py    # Test-Skript zum Vergleich der PDF-Bibliotheken
```

Für den Programmentwurf sind neben den Testdaten im Ordner `arxiv_pdfs` noch die Skripte `rag_import.py` und
`rag_retrieval.py` relevant.

## Installation der benötigten Packages

Um alle benötigten Packages zu installieren, kann der folgende Befehl ausgeführt werden:

```shell
$ pip install -r ./requirements.txt
```

## Import der PDFs in die Datenbank

Das `rag_import`-Skript nimmt keine Kommandozeilenparameter auf und verlässt sich darauf,
dass die Datenbank konfiguriert ist wie in den DevContainer-Einstellungen bzw. in der Ausarbeitung beschrieben und dass
die PDF-Dateien im Projektverzeichnis in `./arxiv_pdfs` gespeichert sind. Die Datenbank-Verbindung und der PDF-Ordner
können allerdings im Skript einfach angepasst werden.

Die Ausführung erfolgt demnach so:

```shell
$ python3 ./rag_import.py
```

## Suchen von PDFs in der Datenbank

Um PDFs zu finden, die zu einem Suchbegriff passen, kann das Skript `rag_retrieval.py` verwendet werden. Auch hier sind
die Datenbank-Credentials im Quellcode fest gesetzt, können aber wie beim Import-Skript leicht angepasst werden.

Um die Datenbank zu durchsuchen, wird das Skript mit dem Suchbegriff als Kommandozeilenparameter aufgerufen, z. B. so:

```shell
$ python3 ./rag_retrieval.py <Suchbegriff>
# z. B.
$ python3 ./rag_retrieval.py "Retrieval Augmented Generation in Data Warehouses"
```

## Vergleich der PDF-Bibliotheken

Zu Projektbeginn musste eine Bibliothek gewählt werden, um die Inhalte der PDF-Dateien einzulesen. Zur Auswahl 
standen die Bibliotheken `pymupdf` und `pdfplumber`, die jeweils sehr unterschiedliche Ergebnisse erzielten,
insbesondere bei Kopf- und Fußzeilen und zweispaltigen Layouts. Um herauszufinden, welche Bibliothek für den
RAG-Import besser geeignet ist, wurde zum Vergleich der Bibliotheken unter Zuhilfenahme von ChatGPT das Skript
`test_pdfparse.py` erstellt. Es enthält Implementierungen für beide PDF-Bibliotheken, wobei eine immer auskommentiert
sein muss. Das Skript erzeugt in jedem Fall ein neues PDF, das auf der linken Seite die betrachtete PDF-Seite zeigt
und auf der rechten Seite den erkannten Text. Die aus dem Ergebnis des Skripts gezogenen Erkenntnisse sind in der 
Ausarbeitung beschrieben.