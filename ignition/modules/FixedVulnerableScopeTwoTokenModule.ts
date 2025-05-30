import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import ProxyFixedVulnerableScopeTwoTokenModule from "./ProxyFixedVulnerableScopeTwoTokenModule";

const FixedVulnerableScopeTwoTokenModule = buildModule(
  "FixedVulnerableScopeTwoTokenModule",
  (m) => {
    const { fixedVulnerableProxy } = m.useModule(ProxyFixedVulnerableScopeTwoTokenModule);

    const fixedVulnerableToken = m.contractAt("FixedVulnerableScopeTwoToken", fixedVulnerableProxy);

    return { fixedVulnerableToken };
  },
);

export default FixedVulnerableScopeTwoTokenModule;
