import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import VulerableTokenModule from "./VulnerableScopeTwoTokenModule";
import FixedVulnerableScopeTwoTokenModule from "./FixedVulnerableScopeTwoTokenModule";

const ReentrancyAttackerModule = buildModule("ReentrancyAttackerModule", (m) => {
  const { vulnerableToken } = m.useModule(VulerableTokenModule);
  const { fixedVulnerableToken } = m.useModule(FixedVulnerableScopeTwoTokenModule);

  const attacker = m.contract("ReentrancyAttacker", [vulnerableToken, fixedVulnerableToken]);

  return { attacker, vulnerableToken, fixedVulnerableToken };
});

export default ReentrancyAttackerModule;
