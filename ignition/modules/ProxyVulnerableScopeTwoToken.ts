import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ProxyVulnerableScopeTwoTokenModule = buildModule("ProxyVulnerableScopeTwoTokenModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);
  console.log("admin owner qqqqqqqqqq", proxyAdminOwner);
  const votingTime = m.getParameter("_timeToVote", 3600);
  const changeVotingThreshold = m.getParameter("changeVotingThreshold", 1000);
  const priceVotingThreshold = m.getParameter("priceVotingThreshold", 500);

  const token = m.contract("VulnerableScopeTwoToken");

  const vulnerableProxy = m.contract("TransparentUpgradeableProxy", [
    token,
    proxyAdminOwner,
    "0x",
  ]);

  const tokenProxy = m.contractAt("VulnerableScopeTwoToken", vulnerableProxy, {
    id: "VulnerableScopeTwoTokenProxy",
  });

  m.call(
    tokenProxy,
    "initialize",
    [votingTime, changeVotingThreshold, priceVotingThreshold],
    { from: proxyAdminOwner }
  );

  const proxyAdminAddress = m.readEventArgument(
    vulnerableProxy,
    "AdminChanged",
    "newAdmin"
  );

  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { vulnerableProxy, proxyAdmin };
});

export default ProxyVulnerableScopeTwoTokenModule;
