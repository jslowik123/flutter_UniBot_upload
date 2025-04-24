class HelpContent {
  static const List<Map<String, dynamic>> pages = [
    {
      'title': 'Welche Dateien kann ich hochladen?',
      'content': [
        'Damit der Chatbot fundierte und genaue Antworten geben kann, solltest du die wichtigsten offiziellen Dokumente hochladen:',
        '• Modulhandbücher',
        '• Studienverlaufspläne',
        '• Prüfungsordnungen',
        '• Sonstige offizielle Dokumente, die textbasiert sind und im Kontext der Universität relevant sind.',
        'Wichtige Hinweise:',
        '• Nur PDF-Dateien werden aktuell unterstützt',
        '• Die Inhalte müssen als Text vorliegen – eingescanntes Bildmaterial oder nicht durchsuchbare PDFs (z. B. reine Scans) funktionieren nicht',
        '• Allgemeine Infos zu ECTS, Hochschulsystem etc. müssen nicht hochgeladen werden – diese Grundlagen kennt das System bereits',
      ],
    },
    {
      'title': 'Was kann der Chatbot beantworten?',
      'content': [
        'Der Chatbot kann bei allen Fragen weiterhelfen, die sich auf die Inhalte deiner hochgeladenen Dokumente beziehen:',
        'Konkrete Fragen:',
        '• „Wann ist die Anmeldefrist für das Modul Data Science?"',
        '• „Wie viele ECTS bekomme ich für BWL I?"',
        '• „Welche Voraussetzungen brauche ich für Künstliche Intelligenz II?"',
        'Komplexe, verknüpfte Fragen:',
        '• „Ich studiere Wirtschaftsinformatik und möchte in Richtung Data Analytics – welche Module sind dafür besonders relevant?"',
        '• „Welche Kombination aus Wahlpflichtfächern würde mir helfen, später im Bereich UX Design zu arbeiten?"',
        'Der Bot ist also nicht nur reaktiv, sondern kann auch kontextbezogene Empfehlungen geben.',
      ],
    },
    {
      'title': 'Tipps & Empfehlungen für optimale Ergebnisse',
      'content': [
        'Dokumente vorbereiten:',
        '• Achte auf eine gute Struktur in den Dokumenten (z. B. klare Überschriften, Inhaltsverzeichnisse, gut lesbarer Text)',
        '• Lade nur aktuelle Versionen der Unterlagen hoch – veraltete Infos können zu Missverständnissen führen',
        '• Verwende sinnvolle Dateinamen, z. B. „Modulhandbuch_Wirtschaftsinformatik_2024.pdf"',
        'Hilfe jederzeit verfügbar:',
        '• Über das Hilfesymbol (?) in der oberen Ecke kannst du die Anleitung jederzeit erneut öffnen',
      ],
    },
    {
      'title': 'Häufige Fragen (FAQ)',
      'content': [
        'Kann ich mehrere Dokumente gleichzeitig hochladen?',
        'Ja, du kannst beliebig viele PDFs in ein Projekt hochladen – je mehr relevante Infos, desto besser die Antworten.',
        'Muss ich technische Vorkenntnisse haben?',
        'Nein. Die App ist so gestaltet, dass sie auch für nicht-technische Nutzer intuitiv bedienbar ist.',
        'Was passiert, wenn der Chatbot falsche Antworten gibt?',
        'KI-Modelle können in seltenen Fällen sogenannte "Halluzinationen" erzeugen. Dank der zugrundeliegenden RAG-Technologie stützt sich der Chatbot aber ausschließlich auf deine Dokumente. Falsche Infos werden so weit wie möglich minimiert.',
      ],
    },
  ];
}
