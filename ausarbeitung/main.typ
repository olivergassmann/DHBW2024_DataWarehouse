#import "@preview/ilm:1.2.1": *

#import "@preview/big-todo:0.2.0": todo
#import "@preview/wordometer:0.1.3": word-count, total-characters, 

#show: word-count

#import "@preview/codly:1.0.0": *
#show: codly-init.with()

#codly(
  languages: (
    py: (
      name: " Python",
      icon: text(font: "tabler-icons", "\u{ed01}"),
      color: rgb("#3572A5")
    ),
    sh: (
      name: " Shell",
      icon: text(font: "tabler-icons", "\u{eb0f}"),
      color: rgb("#4EAA25")
    ),
    sql: (
      name: " SQL",
      icon: text(font: "tabler-icons", "\u{ea88}"),
      color: rgb("#E38C00")
    ),
    yml: (
      name: " Docker-Compose",
      icon: text(font: "tabler-icons", "\u{edca}"),
      color: rgb("#2496ED")
    )
  ),
  stroke: none,
  fill: color.gray.lighten(90%),
)


#set text(lang: "de")
#set figure(placement: auto)

#show: ilm.with(
  title: [RAG Data Engineering: PDF-Umwandlung],
  author: "Oliver Gaßmann",
  date: datetime(year: 2024, month: 12, day: 19),
  date-format: "19. Dezember 2024", // Abgabedatum anstatt Format-String, weil sonst das Datum auf Englisch angezeigt werden würde (z. B. February)
  abstract: [
    Dokumentation zum Programmentwurf\
    Data Warehouse\
    Kurs TINF22B\
    DHBW Stuttgart
  ],
  bibliography: bibliography("zotero.bib"),
  figure-index: (enabled: true, title: "Abbildungsverzeichnis"),
  table-index: (enabled: true, title: "Tabellenverzeichnis"),
  listing-index: (enabled: true, title: "Quellcodeverzeichnis"),
  external-link-circle: true,
)

/*
= AUFGABENSTELLUNG

RAG Data Engineering: pdf Umwandlung

Beschreibung von Data Engineering im Zusammenhang mit RAG mit Schwerpunkt pdf Dokumente in Vektoren umwandeln und in Vektor-DB speichern. Minimum sind 50 Datensätze (Vektoren).

Datenbank: Freie Wahl einer Vektordatenbank
Daten: pdf-Dokumente von https://arxiv.org/
*/

/*
= Wie fange ich an???

Hm. Nach ein bisschen Recherche habe ich zwei Optionen:

Entweder ich lese die kompletten PDFs ein, splitte den Inhalt in zusammenhängende Chunks von ca. 100 Wörtern #math.approx 150-200 Token (u. U. unter Verwendung von Sliding Window) und embedde und speichere jeden Abschnitt einzeln mit dem Modell #link("https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2")[sentence-transformers/all-MiniLM-L6-v2].

Alternativ würde ich nur die Titel und Abstracts verwenden und mit dem auf wissenschaftliche Texte optimierten Embedding-Modell #link("https://huggingface.co/sentence-transformers/allenai-specter")[SPECTER] in Vektoren umwandeln.
*/

= Grundlagen <grundlagen>

Beinahe jeder Überbegriff für Computersysteme -- Informatik, Informationstechnologie (IT) oder Elektronische Datenverarbeitung (EDV) -- beinhaltet einen Hinweis auf Informationen oder Daten. In der modernen Welt gibt es bereits Sprichwörter wie "Daten sind das neue Öl", die von Publikationen des Fraunhofer IML aufgegriffen werden @moller_bedeutung_2017.

Doch Computersysteme können mit einer Menge an Daten allein nicht viel anfangen: Um sinnvoll eingesetzt zu werden, müssen die Daten in maschinenlesbarer Form, schnell zugänglich und gut strukturiert vorliegen. Bei den riesigen Datenmengen, die sekündlich anfallen, wird das zu einer großen Herausforderung, mit der sich das Feld des _Data Engineerings_ (dt. Daten-Ingenieurswesen oder besser Informationsmodellierung) befasst. Beim Data Engineering geht es generell darum, Herangehensweisen für den Umgang mit Daten zu erarbeiten. Dazu gehören die sinnvolle Auswahl von Daten ebenso wie ihre Erfassung bzw. Generierung, Speicherung, Aktualisierung und Nutzung @weber_data_2021[S.~IX]. Tolk @tolk_common_2003 definiert als die Grundlagen des Data Engineering vier Kernkompetenzen:

/ Data Administration: Verwaltung des Informationsaustauschs zwischen Systemen und Definition von Standards sowie Dokumentation.
/ Data Management: Planung, Organisation und Verwaltung der Daten anhand von Regeln und Methoden.
/ Data Alignment: Sicherstellung, dass die benötigten Daten vorhanden sind oder aus vorhandenen Daten abgeleitet werden können.
/ Data Transformation: Technischer Prozess, bei dem die Daten in das benötigte Format gebracht werden, wie vom Data Alignment gefordert.

Obwohl diese Darstellung mittlerweile mehr als zwanzig Jahre alt ist, ist der generelle Ablauf immer noch gültig und werden bei der Planung eines Data Warehouse beachtet. Die ersten drei Kernkompetenzen werden bereits bei der Architektur des Data Warehouse berücksichtigt, die Transformation der Daten erfolgt beim Durchlaufen der Schichten eines Data Warehouse (z. B. _Staging_ #sym.arrow _Core Warehouse Layer_ #sym.arrow _Data Mart_).

Gleichzeitig hat sich auf dem Feld der künstlichen Intelligenz einiges getan, und spätestens seit dem Erscheinen des Large Language Models _ChatGPT_ Ende 2022 @noauthor_introducing_2022 halten KI-Systeme auch Einzug in den Alltag vieler Menschen.

Um auf Kontextwissen zurückgreifen zu können, machen sich einige KI-Modelle die Data Engineering-Technologie _Retrieval-Augmented Generation_, kurz RAG, zunutze. Um RAG nutzen zu können, müssen die Daten kodiert in einem Datenspeicher vorliegen. Stellt ein Nutzer nun eine Anfrage, wird diese an den _Retriever_ übergeben. Dieser sucht im Datenspeicher nach den passendsten Daten und reicht diese gemeinsam mit der Anfrage an den _Generator_ weiter, der anhand der Informationen eine Antwort generiert @zhao_retrieval-augmented_2024. Ein typischer Anwendungsfall für RAG wäre beispielsweise ein auf ein Unternehmen zugeschnittener Chatbot, der nur interne Informationen verwenden soll. In der Regel ist es zu teuer und aufwendig, eine eigene KI auf die eigene, kleine Wissensbasis zu trainieren und setzt stattdessen RAG mit einem vortrainierten Modell ein.

Gleichzeitig wirkt das Vorhalten von "eigenem Wissen" in Form von RAG einem großen Nachteil von Sprachmodellen vor, denn Sprachmodelle neigen dazu, zu halluzinieren -- das heißt, sie geben Informationen wieder, die nicht korrekt sind @schinkels_ki-halluzinationen_2024. Gerade im akademischen Umfeld sind diese Halluzinationen fatal, vor allem wenn sie von Studierenden ungeprüft übernommen werden. Das ist einem Test der Dualen Hochschule Baden-Württemberg zufolge sehr häufig der Fall @bury_test_2023.

Neben dem Generieren vollständiger Texte können KI-Modelle aber auch genutzt werden, um bei der Literatursuche zu unterstützen. Ein prominentes Beispiel dafür ist die wissenschaftliche Suchmaschine #link("https://semanticscholar.org/")[_Semantic Scholar_] des Allen Institute for Artificial Intelligence @cha_paul_2015. Im wissenschaftlichen Kontext kann RAG also auf mehrere Arten bei Forschung und Lehre eingesetzt werden.

Das Ziel dieses Programmentwurfs ist der Aufbau einer RAG-Pipeline mit einer Vektordatenbank für den Umgang mit wissenschaftlichen Preprints von #link("https://arxiv.org/")[arXiv.org]. Die Dokumente liegen im PDF-Format vor.

Für die Umsetzung der Aufgabenstellung ergeben sich aus den zuvor genannten Einsatzzwecken für KI im wissenschaftlichen Kontext zwei Herangehensweisen:
/ RAG für Textgenerierung: Der Inhalt der PDFs wird abschnittsweise in Vektoren eingebettet. So können Daten feingranular abgerufen werden um Fragen präzise zu beantworten.
/ RAG für Dokumentensuche: Titel und Abstract der PDFs werden in Vektoren umgewandelt. So können Artikel gefunden werden, die zum Recherchethema passen.

Für beide Anwendungsfälle stehen Embedding-Modelle zur Verfügung, z. B. #link("https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2")[_all-MiniLM-L6-v2_] für die Textgenerierung und #link("https://huggingface.co/sentence-transformers/allenai-specter")[AllenAI's _SPECTER_] für die Dokumentensuche.

Ein perfekter Chatbot mit optimaler RAG für die Textgenerierung würde viele fachliche Argumente gegen die Verwendung von generativer KI in der Wissenschaft außer Kraft setzen, aber selbst dann würden noch immer moralische Gründe dafür sprechen, eigene Publikationen auch selbst zu schreiben und die Ideen selbst zu entwickeln @aylsworth_should_2024. Aus diesem Grund wird für diesen Programmentwurf die Unterstützung bei der Recherche durch Dokumentensuche als erstrebenswerteres Thema angesehen und SPECTER als Embeddingmodell für die RAG-Pipeline ausgewählt.

#figure(image("diagrams/RAG-Flow.svg"), caption: "Embedding-Flow zum Einfügen von PDFs in die Vektordatenbank") <rag-flow_import>

Damit ergibt sich für den gesamten Datenfluss zum Einlesen von PDFs in die Vektordatenbank der in @rag-flow_import dargestellte Ablauf: Zunächst werden die PDF-Dateien, die manuell von arXiv heruntergeladen wurden, von einem Python-Skript eingelesen und Titel und Abstract der PDFs werden extrahiert. Das Embedding-Modell SPECTER bestimmt anhand von Titel und Abstract dann einen Vektor, der mit dem Titel und dem Abstract in der Vektordatenbank gespeichert wird. Um die Datenbankbelastung gering zu halten, wird das pdf-Dokument selbst in einem separaten Verzeichnis gespeichert und nur der relative Pfad in diesem Verzeichnis wird in der Datenbank abgelegt. Durch die Speicherung von Titel und Abstract in der Datenbank kann so auch bei einem Verlust des Dokumentenverzeichnisses das entsprechende Dokument im Internet recherchiert werden.

#figure(
  image("diagrams/RAG-Retrieval.png"),
  caption: [Retrieval-Flow zum Abrufen von zu einer Nutzereingabe passenden PDFs]
) <rag-flow_retrieval>

Beim Abrufen von Dokumenten aus der Datenbank, dem Retrieval, funktioniert der Ablauf ähnlich, wie @rag-flow_retrieval zeigt: Die Nutzereingabe wird durch dasselbe Embedding-Modell wie die PDF-Dateien in einen Vektor umgewandelt. Daraufhin wird in der Vektordatenbank anhand des Anfragevektors eine Ähnlichkeitssuche nach passenden Dokumenten ausgeführt und die Ergebnisse werden dem Nutzer angezeigt.

= Installation

Für die Umsetzung des Programmentwurfs wird die Programmiersprache Python und das Datenbankmanagementsystem PostgreSQL mit der Erweiterung #link("https://github.com/pgvector/pgvector")[pgvector] verwendet.

== Manuelle Python-Installation

Da Python auf dem Mac bereits vorinstalliert ist, ist keine explizite Installation des Python-Interpreters nötig. Falls eine spezifische Version installiert werden soll, kann dies im Terminal z. B. über den Paketmanager #link("https://brew.sh")[Homebrew] erledigt werden, wie @brew-install-python zeigt.

#figure(```sh
$ brew install python@3.13
```, caption: [Installation des Python-Interpreters in der Version 3.13 über `brew`], placement: none) <brew-install-python>

== Einrichten des Dev-Containers mit PyCharm <dev-container-setup>

Alternativ zur Verwendung von Python auf dem Entwicklungsrechner kann auch ein Development Container mit Docker aufgesetzt werden. Die Verwendung solcher Container stellt sicher, dass Projekte voneinander isoliert ausgeführt werden. Wenn auch PostgreSQL als Container ausgeführt wird, kann die Container-Engine auch das Routing zwischen den Containern übernehmen. Aus diesem Grund wird für diesen Programmentwurf ein vorgefertigtes Dev-Environment aus Docker-Containern mit Python und PostgreSQL verwendet, das sich in der IDE PyCharm einfach erstellen lässt -- vorausgesetzt, Docker (oder ein Drop-In-Replacement) ist installiert. Der Ablauf ist einfach:

1. Nach dem Öffnen von PyCharm kann auf dem Welcome-Bildschirm links der Menüpunkt _Remote Development_ ausgewählt.
2. Ein Klick auf _Create Dev Container_ öffnet das Setup-Menü. Dort kann ausgewählt werden, welche Container-Engine verwendet werden soll, mit welcher JetBrains-IDE gearbeitet wird und welches entfernte Git-Repository auf welchem Branch als Grundlage für den Code verwendet werden soll. Alternativ kann auch ein lokales Projekt angegeben werden.
#figure(image("create_dev_container_config.png", width: 80%), caption: "Konfiguration des Dev-Containers") <create_dev_container_config>
3. Mit dem Button _Build Container and Continue_ wird das Erstellen des Containers gestartet. Sofern das Projekt noch keinen `.devcontainer`-Ordner mit Konfigurationsdateien enthält, wird der Dialog in @create_dev_container_config geöffnet. Darin wird das Template für das Setup der für den Programmentwurf benötigten Umgebung mit Python und PostgreSQL auf `Python 3 & PostgreSQL` gesetzt, der Rest kann bei den Standardwerten belassen werden. 
4. Nach der Bestätigung mit _OK_ wird die Containerumgebung aufgesetzt, Abhängigkeiten werden geladen und installiert. Die Entwicklungsumgebung wird nach dem Deployment entweder automatisch geöffnet oder kann im PyCharm-Willkommensbildschirm über _Remote Development #sym.arrow Dev Containers_ gestartet und geöffnet werden.
5. Standardmäßig verwendet der Dev-Container allerdings das originale Postgres-Image aus dem Docker Hub. Dieses Image stellt allerdings die pgvector-Erweiterung nicht zur Verfügung, daher muss die Containerkonfiguration einmalig angepasst werden: In `.devcontainer/docker-compose.yml` muss das Image der PostgreSQL-Datenbank zu dem von pgvector bereitgestellten Image geändert werden. @change-postgres-image zeigt, welche Änderung vorgenommen werden muss.
#codly(highlights: ((line: 1, start: 7, end: none, fill: green, tag: "statt postgres:latest"), ))
#figure(```yml
    db:
      image: pgvector/pgvector:pg17  
      restart: unless-stopped
      volumes:
        - postgres-data:/var/lib/postgresql/data
      environment:
        POSTGRES_USER: postgres
        POSTGRES_DB: postgres
        POSTGRES_PASSWORD: postgres
    ```, caption: "Relevanter Ausschnitt aus der docker-compose-Datei") <change-postgres-image>
6. Nach dem Anpassen der Docker-Konfiguration muss der Dev-Container neu gebaut werden, damit das DB-Image ausgetauscht wird.

Die Nutzung eines solchen Containers ist allerdings nicht notwendig, alternativ kann auch z.~B. in einem Virtual Environment entwickelt werden. Im Quellcode muss die Datenbankverbindung dann allerdings angepasst werden, um statt dem `db`-Container auf die stattdessen verwendete PostgreSQL-Instanz zu verweisen.

== Installation der `pgvector`-Erweiterung in PostgreSQL

Um die Erweiterung `pgvector` in dem in @dev-container-setup beschriebenen Container (Image `pgvector/pgvector`) zu aktivieren, genügt der SQL-Befehl in @create-extension-pgvector.

#figure(```sql
CREATE EXTENSION vector;
```, placement: none, caption: [Aktivierung der `pgvector`-Erweiterung für PostgreSQL]) <create-extension-pgvector>

Falls das genannte Docker-Image nicht verwendet wird, muss die Erweiterung ggf. erst installiert werden. Details zu diesem Installationsprozess würden den Rahmen dieser Ausarbeitung sprengen und können in der #link("https://github.com/pgvector/pgvector")[Dokumentation von pgvector] nachgelesen werden.

= Umsetzung Beispiel

Nach Abschluss der Installation kann mit der Arbeit am eigentlichen Programmentwurf begonnen werden. Für die erfolgreiche Umsetzung sind vier Schritte zu erledigen: Zunächst muss ein Datenset mit den zu speichernden PDF-Dateien erstellt werden, danach muss aus jedem dieser Dokumenten der Titel und das Abstract extrahiert und gespeichert werden. Im dritten Schritt durchlaufen die so vorbereiteten Daten den RAG-Import-Flow aus @grundlagen (@rag-flow_import) und werden in der Datenbank gespeichert. Im letzten Abschnitt wird die Suche nach Dokumenten realisiert.

== Erstellung des Datensets

Um die Datengrundlage für das Einlesen der Dokumente in die Datenbank zu bewerkstelligen, wurden 51 Preprints im PDF-Format von arXiv heruntergeladen. Da diese im Git-Repository hinterlegt werden, wurde darauf geachtet, dass die Größe eines Artikels 3.5 MB nicht überschreitet -- auch um den PDF-Parser von Python nicht zu überlasten. In einem produktiven Einsatz der Anwendung sollte es problemlos möglich sein, auch größere PDFs zu verarbeiten. Darüber hinaus wurden Preprints aus verschiedenen Kategorien (hauptsächlich Informatik, Astrophysik, Elektrotechnik und Wirtschaft) heruntergeladen, die sich thematisch teilweise drastisch unterscheiden, teilweise aber auch überschneiden. Die Preprints wurden unkatalogisiert und unter ihrem Download-Dateinamen (z. B. `2405.00695v1.pdf`) im Verzeichnis `arxiv-pdfs` abgelegt.

== Vorbereiten der Daten auf den Import <prepare-for-import>

Zum Vorbereiten der zuvor gespeicherten Daten auf das Embedding müssen Titel und Abstract der Artikel ermittelt werden. Die naheliegendste Vorgehensweise dafür ist das Extrahieren dieser aus den PDF-Dateien. Um Text aus PDFs auszulesen, bietet Python unter anderem die Packages PyMuPDF und PDFPlumber, die jeweils unterschiedliche Herangehensweisen an die Textextraktion haben. Um beide zu vergleichen, wurde ein von ChatGPT erstelltes Python-Skript verwendet, das ein Abbild der jeweils ersten Dokumentseite und deren erkannten Textinhalt für alle Artikel in einem PDF-Bericht ausgibt.

In den Berichten erkennt man Probleme bei beiden Packages:
- PyMuPDF kommt mit spaltenweisen Layouts generell gut zurecht, kann aber dafür Ligaturen, wie z. B. LaTeX sie einsetzt, nicht erkennen.
- PDFPlumber erkennt Ligaturen, aber kann spaltenweise Layouts nicht korrekt verarbeiten. Auch vertikaler Text (v. a. die arXiv-Wasserzeichen) sind problematisch. Dem ausgegebenen Text fehlen häufig Leerzeichen.

Neben diesen eher unvorteilhaften Ergebnissen bestehen noch weitere Probleme: Durch möglicherweise vorhandene Kopfzeilen und Zeilenumbrüche im Titel kann die genaue Position der Überschrift nicht ausreichend präzise bestimmt werden. Die Lokalisierung von Abstracts ist oft einfacher, weil sie häufig mit der Überschrift "Abstract" beginnen -- allerdings kann auch das nicht vorausgesetzt werden. Zudem kann das Ende des Abstracts ebenfalls nicht exakt bestimmt werden, da die Folgekapitel keine einheitliche Benennung haben oder manchmal noch Stichworte für die Katalogisierung auf das Abstract folgen (oder ihm vorweg gehen).

Aus diesen Gründen musste die ursprüngliche Strategie aus @rag-flow_import leicht abgeändert werden: Anstatt Titel und Abstract zu extrahieren und somit vorverarbeitet in das SPECTER-Modell zu geben, wird dem Modell der komplette Dokumentbeginn übergeben. Das geht zwar auf Kosten der Genauigkeit der finalen Embeddings, ist für den Rahmen der Aufgabenstellung allerdings durchaus angemessen. Alternativ müsste ein anderes Machine-Learning-Modell zunächst darauf trainiert werden, aus einer Vielzahl unterschiedlicher Formate jeweil Titel und Abstract zu extrahieren, was mit unverhältnismäßig viel Zeit und Aufwand verbunden wäre.

Die Länge des übergebenen Textes richtet sich nach der maximalen Token-Länge von SPECTER, sie beträgt 512 Tokens #footnote[Kann mit Beispielcode aus @aarsen_computing_2024 bestimmt werden.]. Das entspricht etwa 300-400 englischen Wörtern @aarsen_computing_2024. Ein eigenes Experiment mit Blindtext in einer wissenschaftlichen Vorlage hat gezeigt, dass in etwa diese Menge an Text auch auf die erste Seite eines wissenschaftlichen Artikels passt. Daher soll dem Embedding-Modell der gesamte Text der ersten Seite übergeben. Es ist davon auszugehen, dass diese alle für das Embedding relevanten Informationen enthält. Sollte der dem Modell übergebene Text zu lang sein, wird er vor dem Embedding von der Sentence-Transformers-Bibliothek automatisch gekürzt @aarsen_computing_2024. Die Initialisierung des Modells und das Embedding der Textinhalte geht mit der Bibliothek allgemein sehr komfortabel, wie in @embedding_erzeugen ersichtlich ist.

#figure(
  ```py
mod = SentenceTransformer('sentence-transformers/allenai-specter')
# SentenceTransformer can encode multiple inputs at once if a List of strings is provided as input parameter.
embeddings: ndarray = mod.encode(documents, show_progress_bar = True)
```, caption: [Codeausschnitt zum Erzeugen von Vektoren aus einer String-Liste (`documents`)]
) <embedding_erzeugen>

== Import in die Vektordatenbank

Das Sichern der auf diese Weise erzeugten Embedding-Vektoren kann unter Einsatz der Python-Bibliothek `psycopg2` durch einfache SQL-Statements vorgenommen werden. Für den Produktiveinsatz ist die implementierte Vorgehensweise nicht geeignet, da sie für SQL-Injection-Angriffe anfällig ist, allerdings bestehen für dieses Proof-of-Concept keine hohen Sicherheitsanforderungen. Als weitere Vereinfachung wird die Standard-Datenbank `postgres` verwendet, allerdings kann das in der Verbindungskonfiguration angepasst werden (s. @psycop_config). Die restlichen Konfigurationsdaten sind ebenfalls auf den in @dev-container-setup eingerichteten Dev-Container abgestimmt.

#codly(highlights: ((line: 1, start: 7, end: none, fill: green, tag: "hier ggf. andere Datenbank eintragen"), ))
#figure(
  ```py
  connection = psycopg2.connect(
    dbname="postgres",  
    user="postgres",
    password="postgres",
    host="db",
    port="5432"
    ```, caption: [Konfiguration der Datenbankverbindung für `psycopg2`]
) <psycop_config>

Danach erstellt das Python-Skript eine Tabelle für die Artikel-Embeddings, sofern noch keine existiert, und speichert mit einem einfachen SQL-Insert den Dateinamen und den Vektor (im `pgvector`-Format `vector`) in der Datenbank ab.

== Abrufen von Dokumentdaten aus der Vektordatenbank

Die in @prepare-for-import beschriebenen Probleme im Umgang mit PDFs sind beim Abrufen nicht relevant, daher kann hier der ursprünglich geplante Ablauf aus @rag-flow_retrieval problemlos umgesetzt werden. Zur Vereinfachung der Nutzung wird die RAG-Anfrage, also sozusagen der Prompt, direkt als Kommandozeilenparameter an das Python-Skript `rag-retrieval.py` übergeben. Dieser Prompt wird dann mit SPECTER in einen Vektor kodiert, das zeigt @query-encoding. Danach werden über die Ähnlichkeitssuche von pgVector die fünf Dokumente ermittelt, die am ehesten zur Nutzereingabe passen. Dafür wird das SQL-Skript in @sql-similarity-search durch `psycopg2` ausgeführt. Die Ähnlichkeitssuche wird durch den pgVector-Operator `<->` angewendet.

#figure(
  ```py
query = sys.argv[1]
# Embed query
model = SentenceTransformer('sentence-transformers/allenai-specter')
query_vector: ndarray = model.encode(query)
  ```, caption: [Erzeugen eines Vektors aus der Nutzereingabe]) <query-encoding>

#codly(highlights: ((line: 2, start: 2, end: none, fill: green, tag: [%s steht für den Suchvektor]), ))
#figure(
  ```sql
SELECT title
FROM articles
ORDER BY embedding <-> %s::VECTOR  
LIMIT 5;
  ```, caption: [SQL-Statement für die Ähnlichkeitssuche in der Datenbank]
) <sql-similarity-search>

#figure(
  image("rag_retrieval_result.png"),
  caption: [Ergebnis des RAG-Retrieval-Skripts]
) <ergebnis_rag_retrieval>

Trotz des recht einfach gehaltenen Skripts können sich die Ergebnisse sehen lassen: @ergebnis_rag_retrieval zeigt einen beispielhaften Aufrug und die vom Skript gefundenen Dokumente für den Suchbegriff "Retrieval Augmented Generation in Data Warehouses". Die ersten vier Ergebnisse waren erwartbar, da sie alle RAG als Thema haben und auf der ersten Seite mehrfach nennen, aber der fünfte Preprint enthält weder das Schlagwort #text(lang: "en")[_Retrieval Augmented Generation_] noch _Data Warehouse_, ist aber -- wie das Skript bzw. das Embedding-Modell korrekt erkannt hat -- thematisch sehr ähnlich. Damit ist die Einsetzbarkeit des RAG-Workflows bewiesen, da von den Skripten aus der Preprint-Datenbank thematisch passende Artikel empfohlen werden, die teilweise über eine reine Wortsuche nicht auffindbar gewesen wären.

= Hinweis zur Verwendung von generativer KI

Aufgrund der geringen Erfahrung des Autors wurde generative KI eingesetzt, um bestimmte Sprachkonstrukte zu recherchieren. Außerdem wurde das Skript zum Testen der beiden PDF-Bibliotheken von ChatGPT erstellt, da es keinen direkten Bezug zum Thema der Arbeit hat und die Python-Kenntnisse des Autors nicht stark genug ausgeprägt sind, um ein solches Skript selbst zu erstellen. Für das Schreiben dieser Dokumentation keine generative KI eingesetzt. Bei der Erstellung der Skripte `rag-import.py` und `rag-retrieval.py` wurde generative KI nur beratend bei Python-Fragen eingesetzt.