# IF1221 Practicum - Computational Logic: LastNotLeast

> Final project for the Computational Logic course (IF1221), Institut Teknologi Bandung.

This project is a Prolog-based application developed as part of the IF1221 practicum. It explores knowledge representation, inference, and rule-based logic manipulation to simulate a minimalist text-based Pokemon game.

## Installing / Getting Started

This project runs on **GNU Prolog**, not SWI-Prolog.

### Requirements

- GNU Prolog (tested with `gprolog`)
- Operating System: Linux/macOS/WSL/Windows with terminal access

### How to Run

```shell
git clone https://github.com/GAIB22/praktikum-if1221-logika-komputasional-lastnotleast.git
cd praktikum-if1221-logika-komputasional-lastnotleast
gprolog
[main].
start_game.
```

Running `start_game.` will start the interactive Pokemon game simulation.

### Initial Configuration

No additional setup is required. Just ensure all `.pl` files are in the same directory and executed using GNU Prolog.

## Developing

To further develop this project:

```bash
git clone https://github.com/GAIB22/praktikum-if1221-logika-komputasional-lastnotleast.git
cd praktikum-if1221-logika-komputasional-lastnotleast
```

You can modify the game logic, Pokemon facts, battle systems, and more within the Prolog files.

### Directory Structure

```
├── main.pl              # Main entry point
├── peta.pl              # Map definitions and logic
├── Pokemon.pl           # Pokemon facts
├── battle.pl            # Battle mechanisms
├── player.pl            # Player status and position
├── utils.pl             # Utility functions
```

## Features

- Grid-based map representation
- Starter Pokemon selection
- Encounter and battle systems
- Skills and capture mechanics
- Interactive text-based simulation
- Pokemon rarity categories: Common, Rare, Epic, Legendary

## Configuration

No command-line arguments are required. However, you can customize:

- Pokemon facts (`Pokemon.pl`)
- Game world map (`peta.pl`)
- Encounter and level rules

## Contributing

Contributions are welcome!

If you'd like to contribute:

1. Fork this repository
2. Create a new feature branch
3. Commit your changes and submit a pull request

Please follow consistent Prolog styling and include helpful comments for clarity.

## Links

- Repository: [https://github.com/GAIB22/praktikum-if1221-logika-komputasional-lastnotleast](https://github.com/GAIB22/praktikum-if1221-logika-komputasional-lastnotleast)
- GNU Prolog: [http://gprolog.org/](http://gprolog.org/)

## Licensing

The code in this project is licensed under the MIT License.
