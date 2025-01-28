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
  const menu = new Menu();
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
    const choice = await menu.getChoice({
      query: "Add Another Token?",
      items: choices,
      initialIndex: 0,
    });

    addNew = choice === "Yes";
  }

  rl.close();
  return { jsonList, names };
}

// Example usage:
// if (import.meta.url === `file://${process.argv[1]}`) {
//     try {
//         const { jsonList, names } = await getJsonList('1'); // Using Ethereum chain ID
//         console.log('JSON List:', JSON.stringify(jsonList, null, 2));
//         console.log('Names:', names);
//     } catch (error) {
//         console.error('Error:', error);
//         process.exit(1);
//     }
// }

getJsonList("BASE");
