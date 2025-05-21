module.exports = {
  '*.{ts,js}': ['eslint --fix'],
  '*.sol': ['prettier --write', 'npx solhint'],
};
