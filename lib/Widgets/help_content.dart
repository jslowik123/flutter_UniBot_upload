class HelpContent {
  static const List<Map<String, dynamic>> pages = [
    {
      'title': 'Welche Dateien kann ich hochladen?',
      'content': [
        'Damit der Chatbot fundierte und genaue Antworten geben kann, solltest du die wichtigsten offiziellen Dokumente hochladen:',
        '• Modulhandbücher',
        '• Studienverlaufspläne',
        '• Prüfungsordnungen',
        '• Sonstige offizielle Dokumente, die textbasiert sind und im Kontext der Universität relevant sind',
        'Wichtige Hinweise:',
        '• Nur PDF-Dateien werden aktuell unterstützt',
        '• Die Inhalte müssen als Text vorliegen – eingescanntes Bildmaterial oder nicht durchsuchbare PDFs (z. B. reine Scans) funktionieren nicht',
        '• Allgemeine Informationen zu ECTS, Hochschulsystem etc. müssen nicht hochgeladen werden – diese Grundlagen kennt das System bereits',
      ],
    },
    {
      'title': 'Was kann der Chatbot beantworten?',
      'content': [
        'Der Chatbot kann bei allen Fragen weiterhelfen, die sich auf die Inhalte deiner hochgeladenen Dokumente beziehen:',
        'Konkrete Fragen:',
        '• „Wann ist die Anmeldefrist für das Modul XY?"',
        '• „Wie viele ECTS bekomme ich für XY?"',
        '• „Welche Voraussetzungen brauche ich für XY?"',
        'Komplexe, verknüpfte Fragen:',
        '• „Ich studiere X und möchte in Richtung Y – welche Module sind dafür besonders relevant?"',
        '• „Welche Kombination aus Wahlpflichtfächern würde mir helfen, später im Bereich Z zu arbeiten?"',
        'Der Chatbot ist nicht nur statisch, sondern kann auch kontextbezogene Empfehlungen geben.',
      ],
    },
    {
      'title': 'Tipps & Empfehlungen für optimale Ergebnisse',
      'content': [
        'Dokumente vorbereiten:',
        '• Achte auf eine gute Struktur in den Dokumenten (z.B. klare Überschriften, Inhaltsverzeichnisse, gut lesbare Texte)',
        '• Lade nur aktuelle Versionen der Unterlagen hoch – veraltete Informationen können zu Missverständnissen führen',
        '• Verwende sinnvolle Dateinamen, z.B. „Modulhandbuch_Wirtschaftsinformatik_2025.pdf"',
        'Hilfe ist jederzeit verfügbar:',
        '• Über das Hilfesymbol (?) in der oberen Ecke kannst du die Anleitung jederzeit öffnen',
      ],
    },
    {
      'title': 'Häufige Fragen',
      'content': [
        'Kann ich mehrere Dokumente gleichzeitig hochladen?',
        'Ja, du kannst beliebig viele PDFs in ein Projekt hochladen – je mehr relevante Informationen, desto besser die Antworten.',
        'Muss ich technische Vorkenntnisse haben?',
        'Nein, die App ist so gestaltet, dass sie auch für weniger KI-affine Nutzer intuitiv bedienbar ist.',
        'Was passiert, wenn der Chatbot falsche Antworten gibt?',
        'KI-Modelle können in seltenen Fällen sogenannte "Halluzinationen" erzeugen. Dank der zugrundeliegenden RAG-Technologie stützt sich der Chatbot aber ausschließlich auf deine Dokumente. Falsche Informationen werden so weit wie möglich minimiert.',
      ],
    },
  ];
}
