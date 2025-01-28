// menu.js
import { emitKeypressEvents, cursorTo, clearScreenDown } from "readline";
import chalk from "chalk";
class Menu {
  constructor() {
    this.currentSelection = "";
    emitKeypressEvents(process.stdin);
  }

  hideCursor() {
    process.stdout.write("\x1B[?25l");

    // Handle CTRL+C
    process.on("SIGINT", () => {
      this.showCursor();
      process.exit(0);
    });
  }

  showCursor() {
    process.stdout.write("\x1B[?25h");
  }

  renderMenu(instruction, items, selectedIndex, maxViewable = 0) {
    let start = 0;
    let listLength = items.length;
    let longest = Math.max(...items.map((item) => item.length));
    let menuStr = `\n ${instruction}\n`;

    // Handle scrolling view if maxViewable is set
    if (maxViewable !== 0) {
      listLength = Math.min(maxViewable, items.length);
      if (selectedIndex >= listLength) {
        start = selectedIndex + 1 - listLength;
        listLength = selectedIndex + 1;
      }
    }

    // Render menu items
    for (let i = start; i < listLength; i++) {
      const currItem = items[i];
      const spaces = " ".repeat(longest - currItem.length);

      if (i === selectedIndex) {
        this.currentSelection = currItem;
        menuStr += `\n ${chalk.green("ᐅ")} ${chalk.green(currItem)}${spaces}`;
      } else {
        menuStr += `\n   ${currItem}${spaces}`;
      }
    }

    menuStr += "\n";

    // Clear previous menu and render new one
    cursorTo(process.stdout, 0, 0);
    clearScreenDown(process.stdout);
    process.stdout.write(menuStr);
  }

  async getChoice(options) {
    const {
      query = "Select an item from the list:",
      items = [],
      initialIndex = 0,
      maxViewable = 0,
    } = options;

    if (!items.length) {
      console.error(chalk.red("\n [ERROR] No menu items provided"));
      return null;
    }

    let selectedIndex = initialIndex;
    this.hideCursor();
    // Re-enable raw mode for each menu instance
    process.stdin.setRawMode(true);

    return new Promise((resolve) => {
      const handleKeypress = (str, key) => {
        if (key.name === "c" && key.ctrl) {
          this.showCursor();
          process.exit();
        }

        switch (key.name) {
          case "up":
            selectedIndex = (selectedIndex - 1 + items.length) % items.length;
            this.renderMenu(query, items, selectedIndex, maxViewable);
            break;

          case "down":
            selectedIndex = (selectedIndex + 1) % items.length;
            this.renderMenu(query, items, selectedIndex, maxViewable);
            break;

          case "return":
            this.showCursor();
            process.stdin.removeListener("keypress", handleKeypress);
            process.stdin.setRawMode(false);
            resolve(this.currentSelection);
            break;
        }
      };

      process.stdin.on("keypress", handleKeypress);
      this.renderMenu(query, items, selectedIndex, maxViewable);
    });
  }
}

// Example usage:
async function example() {
  const menu = new Menu();
  const foodOptions = [
    "pizza",
    "burgers",
    "chinese",
    "sushi",
    "thai",
    "italian",
  ];

  const firstChoice = await menu.getChoice({
    query: "What do you feel like eating?",
    items: foodOptions,
    initialIndex: 0,
    maxViewable: 4,
  });

  const secondChoice = await menu.getChoice({
    query: "Select another option in case the first isn't available",
    items: foodOptions,
    initialIndex: 0,
    maxViewable: 4,
  });
  console.log(`\n First choice is '${firstChoice}'`);

  console.log(`\n Second choice is '${secondChoice}'`);
}

export default Menu;
