import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import proxyModule from "./ScopeTwoVotingTransferableProxyModule";

const ScopeTwoVotingTransferableModule = buildModule("ScopeTwoVotingTransferableModule", (m) => {
  const { proxy } = m.useModule(proxyModule);

  const token = m.contractAt("ScopeTwoVotingTransferable", proxy);

  return { token };
});

export default ScopeTwoVotingTransferableModule;
