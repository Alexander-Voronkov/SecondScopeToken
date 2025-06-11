import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const VotingTransferableProxyModule = buildModule("VotingTransferableProxyModule", (m) => {
  const proxyAdminOwner = m.getAccount(0);
  console.log("admin owner qqqqqqqqqq", proxyAdminOwner);
  const votingTime = m.getParameter("_timeToVote", 3600);
  const changeVotingThreshold = m.getParameter("changeVotingThreshold", 1000);
  const priceVotingThreshold = m.getParameter("priceVotingThreshold", 500);

  const token = m.contract("ScopeTwoVotingTransferable");

  const proxy = m.contract("TransparentUpgradeableProxy", [
    token,
    proxyAdminOwner,
    "0x",
  ]);

  const tokenProxy = m.contractAt("ScopeTwoVotingTransferable", proxy, {
    id: "ScopeTwoVotingTransferableProxy",
  });

  m.call(
    tokenProxy,
    "initialize",
    [votingTime, changeVotingThreshold, priceVotingThreshold],
    { from: proxyAdminOwner }
  );

  const proxyAdminAddress = m.readEventArgument(
    proxy,
    "AdminChanged",
    "newAdmin"
  );

  const proxyAdmin = m.contractAt("ProxyAdmin", proxyAdminAddress);

  return { proxy, proxyAdmin };
});

export default VotingTransferableProxyModule;
