import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import vulerableTokenModule from "./VulnerableScopeTwoTokenModule";

const ReentrancyAttackerModule = buildModule("ReentrancyAttackerModule", (m) => {
  const { vulnerableToken } = m.useModule(vulerableTokenModule);

  const attacker = m.contract("ReentrancyAttacker", [vulnerableToken]);

  return { attacker, vulnerableToken };
});

export default ReentrancyAttackerModule;
