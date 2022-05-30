async function main() {
  console.log(`USE 'yarn deploy --network <network>'`)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
