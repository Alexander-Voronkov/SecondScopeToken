import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import scopeTwoTokenModule from "./ProxyModule";

const upgradeModule = buildModule("UpgradeModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);

  const { proxyAdmin, proxy } = m.useModule(scopeTwoTokenModule);

  const demoV2 = m.contract("Some New Module");

  const encodedFunctionCall = m.encodeFunctionCall(demoV2, "setName", [
    "Example Name",
  ]);

  m.call(proxyAdmin, "upgradeAndCall", [proxy, demoV2, encodedFunctionCall], {
    from: proxyAdminOwner,
  });

  return { proxyAdmin, proxy };
});