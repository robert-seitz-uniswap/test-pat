import Menu from "./menu.js";
import { getTokenFromApi } from "./getTokenFromApi.js";
import { getChainIdFromName } from "./getChainIdFromName.js";
import readline from "readline";

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, resolve);
  });
}

export async function getJsonList(chainName) {
  let menu = new Menu();
  let jsonList = [];
  let names = [];
  let addNew = true;

  while (addNew) {
    // Get token address and details
    const address = await question("enter address: ");
    const token = await getTokenFromApi(chainName, address);
    const logoURI = await question("enter logo url (optional): ");

    // Create token object
    const jsonObject = {
      chainId: getChainIdFromName(chainName),
      address: token.address,
      name: token.name,
      symbol: token.symbol,
      decimals: token.decimals,
      logoURI: logoURI || "",
    };

    // Add to our lists
    jsonList.push(jsonObject);
    names.push(token.name);

    // Ask if user wants to add another token
    const choices = ["No", "Yes"];
    menu = new Menu();
    const choice = await menu.getChoice({
      query: "Add Another Token?",
      items: choices,
      initialIndex: 0,
    });

    addNew = choice === "Yes";
  }

  return { jsonList, names };
}

export function closeReadline() {
  if (rl) {
    rl.close();
    rl = null;
  }
}
