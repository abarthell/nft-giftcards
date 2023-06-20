async function main() {
    const OptimismPass = await hre.ethers.getContractFactory('OptimismPass');
    const optimismPass = await OptimismPass.deploy();

    await optimismPass.deployed();

    console.log(
        `OptimismPass deployed to: ${optimismPass.address}`
    );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});