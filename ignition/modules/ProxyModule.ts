import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const proxyModule = buildModule("ProxyModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);

  const demo = m.contract("ScopeTwoToken");

  const initCallData = m.call(demo, "initialize", [
    3600,
    1000,
    500  
  ]);

  const proxy = m.contract("TransparentUpgradeableProxy", [
    demo,
    proxyAdminOwner,
    initCallData,
  ]);

  const proxyAdminAddress = m.readEventArgument(
    proxy,
    "AdminChanged",
    "newAdmin"
  );

  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { proxyAdmin, proxy };
});

const scopeTwoTokenModule = buildModule("ScopeTwoTokenModule", (m) => {
  const { proxy, proxyAdmin } = m.useModule(proxyModule);

  const scopeTwoToken = m.contractAt("ScopeTwoToken", proxy);

  return { scopeTwoToken, proxy, proxyAdmin };
});

export default scopeTwoTokenModule;