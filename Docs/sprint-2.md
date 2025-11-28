# Sprint 2 Plan
---
### Goals
- PGN support
  - The user should be able to input a PGN through text or file
  - The app should be able to parse the PGN/Use Stockfish to analyze it
  - Validate input to ensure it is a valid PGN/FEN
---
- Board Visualization
  - The app should display the FEN or PGN as a board
  - The board state should be accurate and easy to read
- Motif Detection and Displaying
  - Use Stockfish to detect and label moves as mistakes, blunders, great moves, etc...
  - Use output from Stockfish to detect and display common motifs
  - Summary display (Optional)
---
### Metrics
- Number of individual features planned: 3
- Number of individual requirements planned: 8
---
### Timeline and Milestones
- Week 1: Finish PGN/FEN support feature and it's requirements
- Week 2: Finish Board Visualization feature and its requirements
- Week 3: Stockfish detects and labels moves as mistakes, blunders, great moves, etc...
- Week 4:  Rest of Motif Detection and Displaying Requirements
- Week 5: UI improvements/Flex week
---
### Weekly Progress
- Week 1: Board Visualization added
- Week 2: StockfishHelper was refactored. PGN feature was worked on but later disabled due to complications
- Week 3: ChessGUI was created.
- Week 4: Engine Analysis Model was created
- Week 5:  Motif Detection Model was created.