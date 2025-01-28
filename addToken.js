import { execSync } from "child_process";
import { existsSync } from "fs";
import Menu from "./menu.js";
import { getJsonList, closeReadline } from "./addToJsonList.js";
import { getChainIdFromName } from "./getChainIdFromName.js";
import { getChainNameFromId } from "./getChainNameFromId.js";

async function addToken() {
  process.stdin.setRawMode(true);
  process.stdin.resume();
  try {
    console.clear();

    // Select token list repository
    const menu = new Menu();
    const choices = ["default", "extended", "unsupported"];
    const selectedChoice = await menu.getChoice({
      query: "Select List",
      items: choices,
      initialIndex: 0,
    });

    // Set repository based on selection
    let repository;
    let folderName;
    switch (selectedChoice) {
      case "default":
        repository = "git@github.com:Uniswap/default-token-list.git";
        break;
      case "extended":
        repository = "git@github.com:Uniswap/extended-token-list.git";
        break;
      case "unsupported":
        repository = "git@github.com:Uniswap/unsupported-token-list.git";
        break;
    }

    // Extract folder name from repository URL
    folderName = repository.split("Uniswap/")[1].replace(".git", "");

    // Install dependencies if needed
    if (!existsSync("node_modules")) {
      console.log("installing dependencies");
      execSync("npm install", { stdio: "inherit" });
    }

    // Clone repository if needed
    if (!existsSync(folderName)) {
      console.log("cloning");
      execSync(`git clone ${repository}`, { stdio: "inherit" });
    }

    // Change directory and update repo
    process.chdir(`./${folderName}/src/tokens`);
    execSync("git reset --hard && git checkout main && git pull", {
      stdio: "inherit",
    });

    // Get list of chain files
    const files = execSync("ls -1")
      .toString()
      .split("\n")
      .filter(Boolean)
      .map((file) => file.replace(/\.json$/, ""));

    // Process chains
    let addAnotherChain = "Yes";
    const allNames = [];
    let names = [];

    while (addAnotherChain === "Yes") {
      const chainMenu = new Menu();
      const selectedChain = await chainMenu.getChoice({
        query: "Select Chain",
        items: files,
        initialIndex: 0,
      });

      const chainName = getChainIdFromName(selectedChain);
      const chainId = getChainNameFromId(chainName);

      const { jsonList, names: newNames } = await getJsonList(chainId);

      // Update JSON file
      const currentFile = `./${selectedChain}.json`;
      const currentContent = JSON.parse(
        execSync(`cat ${currentFile}`).toString()
      );
      const updatedContent = [...currentContent, ...jsonList];

      execSync(
        `echo '${JSON.stringify(updatedContent, null, 2)}' > ${currentFile}`
      );

      allNames.push(...newNames);
      names = newNames;

      const continueChoices = ["Yes", "No"];

      addAnotherChain = await new Menu().getChoice({
        query: "Modify Another Chain?",
        items: continueChoices,
        initialIndex: 0,
      });
    }

    // Create branch and commit changes
    const random = Math.floor(Math.random() * 100) + 1;
    const date = new Date().toISOString().split("T")[0];
    const branchName = `add-${allNames.join("-")}-${date}-${random}`.replace(
      /\s+/g,
      "_"
    );

    execSync(`git checkout -b ${branchName}`, { stdio: "inherit" });
    execSync("git add -u", { stdio: "inherit" });

    const commitMsg = `add ${names.join(" ")}`;
    execSync(`git commit -m "${commitMsg}"`, { stdio: "inherit" });
    execSync("npm version minor", { stdio: "inherit" });
    execSync("git push -u -f origin HEAD", { stdio: "inherit" });
    execSync("gh pr create", { stdio: "inherit" });
    execSync("git checkout main", { stdio: "inherit" });
  } catch (error) {
    console.log("error");
    process.stdin.setRawMode(false);
    process.stdin.pause();
    console.error(error);
  } finally {
    process.stdin.setRawMode(false);
    process.stdin.pause();
    closeReadline();
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  addToken().catch(console.error);
}

export { addToken };
