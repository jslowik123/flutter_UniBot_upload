class HelpContent {
  static const List<Map<String, dynamic>> pages = [
    {
      'title': 'Projekt-Dashboard Übersicht',
      'content': [
        'Das Projekt-Dashboard ist die zentrale Anlaufstelle für die Verwaltung deines Projekts.',
        'Navigation:',
        '• Übersicht: Zeigt Projekt-Notizen, Assessment, Wissensbasis, Fortschritt und Beispiel-Fragen',
        '• Dateien: Verwalte und lade PDF-Dokumente hoch',
        'Dashboard-Komponenten:',
        '• Projekt-Notizen: Gib wichtige Kontextinformationen für den Chatbot ein',
        '• Vollständigkeits-Indikator: Zeigt die Qualität deiner Dokumentenbasis',
        '• Projekt-Assessment: Automatische Bewertung der hochgeladenen Dokumente',
        '• Wissensbasis: Übersicht über extrahierte Informationen aus deinen Dokumenten',
        '• Beispiel-Fragen: Zeigt typische Fragen und Antworten für dein Projekt',
        'Wichtig: Die Projekt-Notizen sind essentiell für eine korrekte Vollständigkeits-Bewertung! Ohne diese Angaben kann das System nicht einschätzen, welche Dokumente für dein spezifisches Projekt relevant sind.',
      ],
    },
    {
      'title': 'Datei-Upload & Verarbeitung',
      'content': [
        '• Der Upload von Dateien erfolgt asynchron. Du kannst währenddessen weiterarbeiten.',
        '• Es werden nur PDF-Dateien unterstützt, deren Inhalt als Text vorliegt (keine reinen Scans/Bilder).',
        '• Reine Scans (gescannte Bilder ohne erkannten Text) können nicht verarbeitet werden.',
        '• Wenn dein PDF Grafiken, Tabellen oder Diagramme enthält, gib beim Upload die entsprechenden Seitenzahlen an.',
        '• Diese Angabe hilft dem System, visuelle Inhalte korrekt zu verarbeiten.',
        '• Nach dem Upload werden die Dateien automatisch analysiert und in die Wissensbasis aufgenommen.',
        '• Der Verarbeitungsfortschritt wird in der Oberfläche angezeigt.',
        '• Je mehr relevante und gut strukturierte Dokumente du hochlädst, desto besser werden die Ergebnisse.',
      ],
    },
    {
      'title': 'Assessment & Wissensbasis',
      'content': [
        'Das System erstellt automatisch eine Bewertung deines Projekts (Assessment) und eine Wissensbasis:',
        'Assessment:',
        '• Zeigt vorhandene und fehlende Dokumenttypen',
        '• Gibt Tipps für Verbesserungen',
        '• Aktualisiert sich automatisch bei neuen Uploads',
        'Vollständigkeits-Indikator:',
        '• Zeigt die Qualität deiner Dokumentenbasis in Prozent (confidence)',
        '• Grün (80-100%): Sehr gute Grundlage',
        '• Orange (60-79%): Solide Basis, weitere Dokumente empfohlen',
        '• Rot (unter 60%): Mehr Dokumente für bessere Ergebnisse nötig',
        'Wissensbasis:',
        '• Überblick über extrahierte Informationen',
        '• Zeigt den aktuellen Wissensstand des Chatbots',
        'Tipp: Lade alle relevanten Dokumente hoch und fülle die Notizen aus, um ein möglichst vollständiges Assessment zu erhalten.',
      ],
    },
    {
      'title': 'Beispiel-Fragen',
      'content': [
        'Im Dashboard werden automatisch drei Beispiel-Fragen mit passenden Antworten angezeigt.',
        '• Diese Fragen werden auf Basis deiner hochgeladenen Dokumente und Notizen generiert.',
        '• Sie helfen dir, typische Anwendungsfälle und die Fähigkeiten des Systems besser zu verstehen.',
        '• Du kannst die Beispiel-Fragen jederzeit neu generieren lassen.',
        // Konkrete Beispiel-Fragen und Antworten entfernt
      ],
    },
    {
      'title': 'Tipps für erfolgreiche Projekte',
      'content': [
        '• Verwende klare Projektnamen und Beschreibungen, z.B. "Bachelor BWL PO 2023"',
        '• Füge in die Projekt-Notizen wichtige Kontextinformationen hinzu',
        '• Mische nicht zu viele unterschiedliche Themen in einem Projekt',
        '• Erstelle für verschiedene Studiengänge separate Projekte',
        '• Achte auf den Vollständigkeits-Indikator im Dashboard',
        '• Lies das automatische Assessment, um fehlende Dokumente zu identifizieren',
        '• Teste regelmäßig mit typischen Fragen',
        '• Halte deine Dokumente aktuell und entferne veraltete Dateien',
      ],
    },
  ];
}