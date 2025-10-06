import { goerli, mainnet } from "viem/chains";
export const presaleStartTime = 1693432800;

const config = {
  chains: [mainnet],
  whitepaper: "#",
  telegram: "https://t.me/zilab_technologies",
  twitter: "#",

  stage: {
    name: "Stage 1",
    total: 5_000_000, // total sale amount
  },

  presaleContract: {
    [goerli.id]: "0xa888c0c93515ef3f9e66a927dc92ca08c8f2b43c",
    [mainnet.id]: "0x0ccd64f8b409dc1f72207c9636c19347045056fB",
  } as { [key: number]: Address }, // presale contract address

  saleToken: {
    [mainnet.id]: {
      address: "0x0Ea793e7E1D3B4a79343FF5882a9C3429e6B6Ca2", // token address
      symbol: "TTT", // token symbol
      name: "Token", // token name
      image: "/img/tokens/logoipsum-296.svg", // token image
      decimals: 8, // token decimals
    },
    [goerli.id]: {
      address: "0xc71aac019D4d2aaD5535dC92FE58d78ae09Dc6D6", // token address
      symbol: "BNS", // token symbol
      name: "PopTok Token", // token name
      image: "/img/tokens/INSIG.png", // token image
      decimals: 6, // token decimals
    },
  } as { [key: number]: Token },

  displayPrice: {
    [mainnet.id]: "USDT",
    [goerli.id]: "USDT",
  } as { [key: number]: string },

  whitelistedTokens: {
    [mainnet.id]: [
      {
        address: null,
        symbol: "ETH",
        name: "Ethereum",
        image:
          "https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa5/svg/color/eth.svg",
        decimals: 18,
      },
      {
        address: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        symbol: "USDT",
        name: "Tether USD",
        image:
          "https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa5/svg/color/usdt.svg",
        decimals: 6,
      },
      /* {
        address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
        symbol: "USDC",
        name: "USDC",
        image: "https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa5/svg/color/usdc.svg",
        decimals: 6,
      },
      {
        address: "0x4fabb145d64652a948d72533023f6e7a623c7c53",
        symbol: "BUSD",
        name: "BUSD",
        image: "https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa5/svg/color/bnb.svg",
        decimals: 18,
      },*/
    ],
    [goerli.id]: [
      {
        address: null,
        symbol: "ETH",
        name: "Ethereum",
        image:
          "/img/tokens/eth.png",
        decimals: 18,
      },
      {
        address: "0x053B0f6b94B74E15B0d373E7B5E47Cbe19B9d005",
        symbol: "USDT",
        name: "Tether USD",
        image:
          "/img/tokens/tethernew_32.webp",
        decimals: 18,
      },
    ],
  } as { [key: number]: Token[] },
};

export default config;
