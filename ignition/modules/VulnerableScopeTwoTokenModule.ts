import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import proxyModule from "./ProxyVulnerableScopeTwoToken";

const VulnerableScopeTwoTokenModule = buildModule("VulnerableScopeTwoTokenModule", (m) => {
  const { vulnerableProxy } = m.useModule(proxyModule);

  const vulnerableToken = m.contractAt("VulnerableScopeTwoToken", vulnerableProxy);

  return { vulnerableToken };
});

export default VulnerableScopeTwoTokenModule;
