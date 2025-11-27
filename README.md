# Space Shooter

A roguelike space shooter game built with Flutter and Flame engine. Survive waves of enemies, collect upgrades, defeat bosses, and climb the global leaderboard!

## Play Now

[Play on GitHub Pages](https://abdelaziz-mahdy.github.io/space_shooter/)

## Features

### Gameplay
- **Infinite Survival Mode** - Fight endless waves of increasingly difficult enemies
- **Roguelike Upgrades** - Choose from 40+ upgrades with 4 rarity tiers (Common, Rare, Epic, Legendary)
- **Multiple Weapons** - Unlock and switch between unique weapons:
  - Pulse Cannon - Balanced starter weapon
  - Plasma Spreader - Wide spread shots
  - Railgun - High damage piercing shots
  - Missile Launcher - Homing missiles with explosions
- **Boss Battles** - Face 10 unique bosses with different attack patterns:
  - Summoner, Gunship, Fortress, Hydra, Vortex, Architect, Shielder, Splitter, Nexus, Berserker

### Enemies
- **Triangle** - Basic enemy, moves toward player
- **Square** - Tanky enemy with more health
- **Pentagon** - Fast-moving enemy
- **Ranger** - Shoots projectiles from distance
- **Scout** - Agile enemy that flees and returns
- **Kamikaze** - Charges at player and explodes
- **Tank** - Slow but heavily armored

### Power-Ups
- **Health** - Restore HP
- **Magnet** - Attract all XP orbs
- **Bomb** - Clear screen of enemies

### Upgrade System
Upgrades are categorized by rarity with weighted drops:
- **Common (60%)** - Basic stat boosts (damage, speed, health, etc.)
- **Rare (25%)** - Advanced abilities (pierce, freeze, chain lightning)
- **Epic (12%)** - Powerful effects (bullet storm, time dilation, phoenix rebirth)
- **Legendary (3%)** - Game-changing upgrades (glass cannon, infinity orbitals, perfect harmony)

### Global Leaderboard
- Submit your scores to compete globally
- View other players' runs including their upgrade choices
- Track your local high scores

## Controls

### Desktop
- **WASD / Arrow Keys** - Move
- Auto-aim and auto-fire at nearest enemy

### Mobile
- **Virtual Joystick** - Touch and drag to move
- Auto-aim and auto-fire at nearest enemy

## Tech Stack

- **Flutter** - Cross-platform UI framework
- **Flame** - 2D game engine for Flutter
- **Vercel** - Serverless backend for leaderboard
- **Neon** - PostgreSQL database for scores

## Development

### Prerequisites
- Flutter SDK 3.10+
- Dart SDK 3.0+

### Setup

```bash
# Clone the repository
git clone https://github.com/abdelaziz-mahdy/space_shooter.git
cd space_shooter

# Install dependencies
flutter pub get

# Run the game
flutter run
```

### Build for Web

```bash
flutter build web --release --wasm
```

### Environment Variables (Optional)

For leaderboard functionality, create a `.env` file:

```
LEADERBOARD_API_URL=https://your-vercel-deployment.vercel.app/api
```

## Project Structure

```
lib/
├── components/          # Game entities (player, enemies, bullets, etc.)
│   ├── bosses/         # Boss enemy implementations
│   ├── enemies/        # Regular enemy types
│   └── power_ups/      # Power-up items
├── config/             # Game configuration
├── factories/          # Entity factories
├── game/               # Main game class
├── managers/           # Game state managers
├── services/           # External services (scores, leaderboard)
├── ui/                 # Flutter UI components
├── upgrades/           # Upgrade system
├── utils/              # Utility classes
└── weapons/            # Weapon implementations
```

## License

MIT License - feel free to use this code for your own projects!

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
