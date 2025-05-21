import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import proxyModule from "./ProxyModule";

const ScopeTwoTokenModule = buildModule("ScopeTwoTokenModule", (m) => {
  const { proxy } = m.useModule(proxyModule);

  const token = m.contractAt("ScopeTwoToken", proxy);

  return { token };
});

export default ScopeTwoTokenModule;
