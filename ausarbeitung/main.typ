#import "@preview/ilm:1.2.1": *

#set text(lang: "de")

#show: ilm.with(
  title: [RAG Data Engineering: PDF-Umwandlung],
  author: "Oliver Gaßmann",
  date: datetime(year: 2024, month: 12, day: 19),
  date-format: "19. Dezember 2024", // Abgabedatum anstatt Format-String, weil sonst das Datum auf Englisch angezeigt werden würde (z. B. February)
  abstract: [
    Dokumentation zum *Programmentwurf* in der\
    Vorlesung *Data Warehouse*\
    Kurs *TINF22B*\
    DHBW Stuttgart
  ],
  bibliography: bibliography("zotero.bib"),
  figure-index: (enabled: true),
  table-index: (enabled: true),
  listing-index: (enabled: true),
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

= Grundlagen

Beinahe jeder Überbegriff für Computersysteme -- Informatik, Informationstechnologie (IT) oder Elektronische Datenverarbeitung (EDV) -- beinhaltet einen Hinweis auf Informationen oder Daten. In der modernen Welt gibt es bereits Sprichwörter wie "Daten sind das neue Öl", die von Publikationen des Fraunhofer IML aufgegriffen werden @moller_bedeutung_2017.

Doch Computersysteme können mit einem Haufen Daten allein nicht viel anfangen: Um sinnvoll eingesetzt zu werden, müssen die Daten in maschinenlesbarer Form, schnell zugänglich und gut strukturiert vorliegen. Bei den riesigen Datenmengen, die sekündlich anfallen, wird das zu einer großen Herausforderung, mit der sich das Feld des _Data Engineerings_ (dt. Daten-Ingenieurswesen oder besser Informationsmodellierung) befasst. Beim Data Engineering geht es generell darum, Herangehensweisen für den Umgang mit Daten zu erarbeiten. Dazu gehören die sinnvolle Auswahl von Daten ebenso wie ihre Erfassung bzw. Generierung, Speicherung, Aktualisierung und Nutzung @weber_data_2021[S.~IX]. Tolk @tolk_common_2003 definiert als die Grundlagen des Data Engineering vier Kernkompetenzen:

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


= Installation



= Umsetzung Beispiel



