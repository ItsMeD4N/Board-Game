# IF1221 Final Project - Pokemon Board Game

> Final project for the Computational Logic course (IF1221), Institut Teknologi Bandung.

This project is a Prolog-based board game developed as part of the IF1221 practicum. It explores knowledge representation, inference, and rule-based logic manipulation to simulate a text-based Pokemon board game.

## 🧰 Requirements

- GNU Prolog (tested with `gprolog`)
- OS: Linux, macOS, Windows (via WSL or terminal access)

## ▶️ How to Run

```bash
git clone https://github.com/ItsMeD4N/Board-Game.git
cd Board-Game
gprolog
[main].
start_game.
```

Running `start_game.` will launch the interactive Pokemon board game.

## 🛠️ Project Structure

```
├── main.pl              # Entry point of the game
├── map.pl               # Grid-based map logic
├── pokemon.pl           # Pokemon definitions and facts
├── battle.pl            # Turn-based battle system
├── player.pl            # Player data and mechanics
├── skill.pl             # Skill definitions and usage
├── item.pl              # Item definitions and inventory
├── enemy.pl             # Wild Pokemon and enemy encounters
├── utils.pl             # Utility predicates
```

## 🎮 Features

- Grid-based world and movement
- Starter Pokemon selection
- Wild encounters and turn-based battles
- Skills, items, and capturing mechanics
- Dynamic rarity system (Common to Legendary)
- Goal-based game win condition

## ✏️ Development Tips

You can customize or expand the game by editing the `.pl` files directly, such as:

- Adding more Pokemon in `pokemon.pl`
- Changing the map layout in `map.pl`
- Tuning battle rules in `battle.pl`

## 🙌 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a new feature branch
3. Commit your changes and open a Pull Request

Please follow consistent Prolog styling and add comments for clarity.

## 🔗 Useful Links

- Repository: [https://github.com/ItsMeD4N/Board-Game](https://github.com/ItsMeD4N/Board-Game)
- GNU Prolog: [http://gprolog.org/](http://gprolog.org/)

## 🪪 License

This project is licensed under the MIT License.

<p align="center">
  Made with ❤️ by <a href="https://github.com/ItsMeD4N">ItsMeD4N</a>
</p>
