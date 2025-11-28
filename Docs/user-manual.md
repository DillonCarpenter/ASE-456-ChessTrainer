---
marp: true
theme: default
paginate: true
---

# Chess Trainer App
**User Manual**

---

## Overview

- Mobile app for **Android** and **iOS**.
- Provides chess board visualization and engine analysis.
- Powered by **Stockfish** and **Motif detection**.
- Designed for training and learning chess positions.

---

## Platform
- Android or iOS device or emulator is needed
- Android Studio is Recommended

---

## Input Options

### FEN (Recommended)

- Enter a **FEN string** to display a position.
- Correct FEN formatting is **required**.
- Example:  
`rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1`

> ⚠ Without proper FEN, the app cannot analyze or display positions.

---

### PGN (Currently Disabled)

- Loading full **PGN games** is not available in this version.
- PGN support may be added in future releases.

---

## Navigating Positions

- Use the **forward** and **backward arrows** to move between positions (if multiple FENs are provided).  
- Current position indicator: `1 / N` (shows your place in the sequence).  

---

## Engine Analysis

- Stockfish evaluates each position.  
- Displays **PV lines** (principal variations) with depth and evaluation.  
- Example:


---

## Motif Detection

- Shows key **pawn structures** and **endgame types**.
- Example output for a position:

- Pawn Islands (W/B): 1 / 1  
- Queenside Majority (W/B): false / true  
- Pawn Structure (White): iso 0, dbl 0, tri 0  
- Pawn Structure (Black): iso 0, dbl 1, tri 0  
- Endgame Type: none  

---

## Important Notes

- Only **single FEN inputs** are fully functional.  
- Ensure **FEN strings are valid**; otherwise, analysis will fail.  
- PGN functionality is currently **disabled**.  
- App is optimized for mobile usage — orientation locked to **portrait**.

---

## Contact & Support

For questions or issues:

- Email: carpenterd5@nku.edu
- Documentation: [Chess Trainer Docs](https://github.com/DillonCarpenter/ASE-456-ChessTrainer/tree/main/Docs) 

---

# Thank You

- Enjoy learning chess efficiently!
- Stockfish + Motif detection = smarter training.
