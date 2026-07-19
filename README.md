# Hall Family Tree

A comprehensive genealogy database and web interface for the Hall family lineage, serving as a self-hosted alternative to commercial genealogy platforms.

## Purpose

This repository contains the complete Hall family genealogy data, documentation, and web interface to preserve family history independently of commercial services.

## Structure

```
hall-family-tree/
|-- data/
|   |-- family-tree.json      # Core family tree data
|   |-- sources/              # Document citations and sources
|   |-- media/                # Photos and documents
|   |-- dna/                  # DNA match data
|   `-- research/             # Research notes and logs
|-- web/
|   |-- index.html            # Main family tree interface
|   |-- css/                  # Stylesheets
|   |-- js/                   # JavaScript functionality
|   `-- assets/               # Images and resources
|-- exports/                  # GEDCOM and other exports
|-- docs/                     # Documentation
|   |-- final-ledger.md       # Asa Hall research summary (2026)
|   |-- final-ledger.html     # Print-ready manuscript
|   |-- final-ledger.pdf      # Generated print PDF
|   `-- build-pdf.bat         # Regenerate PDF from HTML
`-- backups/                  # Regular data backups
```

## Features

- **Family Tree Visualization**: Interactive pedigree charts
- **Document Management**: Source citation and evidence tracking
- **DNA Integration**: Segment mapping and relationship analysis
- **Research Tools**: Verification workflow and logging
- **Data Export**: GEDCOM, PDF, and CSV exports
- **Backup System**: Multiple redundancy layers

## Getting Started

1. Clone this repository
2. Open `web/index.html` in your browser
3. Navigate the family tree using the interactive interface

## Data Format

Family tree data is stored in JSON format for easy parsing and manipulation. See `data/family-tree.json` for the complete structure.

## Privacy

This repository contains sensitive family information. Access should be limited to family members and authorized researchers.

## License

Family data remains private. Code and structure may be shared under appropriate license for family use.

## Updating the Final Ledger PDF

1. Edit `docs/final-ledger.html` (or `docs/final-ledger.md` and convert).
2. Double-click `docs/build-pdf.bat` to regenerate `docs/final-ledger.pdf`.
3. Commit and push both files.

---

*Last updated: 2026-07-19*
