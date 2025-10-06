import config, { presaleStartTime } from "../config";
import { RootState } from "../store";
import { useSelector, useDispatch } from "react-redux";
import {
  setSaleStatus,
  setTokenPrice,
  setTotalTokensforSale,
  setTotalTokensSold,
} from "../store/presale";
import { useMemo, useState } from "react";
import { erc20ABI, useAccount, usePublicClient, useWalletClient } from "wagmi";
import { setBalance } from "../store/wallet";
import { toast } from "react-toastify";

import {
  createPublicClient,
  formatUnits,
  getContract,
  http,
  parseUnits,
  zeroAddress,
} from "viem";
import { presaleAbi } from "../contracts/presaleABI";
import { storeReferralTransaction, storeTransaction } from "../utils/apis";
import dayjs from "dayjs";

const INFURA_PROJECT_ID = "1b2ba01443a94ae6895ba4088f79d129";

const publicClient = createPublicClient({
  chain: config.chains[0],
  transport: http(`https://mainnet.infura.io/v3/${INFURA_PROJECT_ID}`),
  batch: { multicall: true },
});

const useWeb3Functions = () => {
  const chainId = useSelector(
    (state: RootState) => state.presale.chainId as ChainId
  );
  const [loading, setLoading] = useState(false);
  const tokens = useSelector((state: RootState) => state.presale.tokens);
  const dispatch = useDispatch();
  const provider = usePublicClient();
  const { data: walletClient } = useWalletClient();
  const { address } = useAccount();

  const presaleContract = useMemo(
    () =>
      getContract({
        address: config.presaleContract[chainId],
        abi: presaleAbi,
        walletClient: walletClient || undefined,
        publicClient,
      }),
    [walletClient, chainId]
  );

  const fetchIntialData = async () => {
    setLoading(true);

    const [saleStatus] = await Promise.all([
      presaleContract.read.saleStatus(),
      fetchTotalTokensSold(),
      fetchTokenPrices(),
    ]);

    dispatch(setSaleStatus(saleStatus));

    setLoading(false);
  };

  const fetchTotalTokensSold = async () => {
    let extraAmount = 0;
    let incrase = 0;

    const totalTokensSold = await presaleContract.read.totalTokensSold();

    try {
      const resposne = await fetch("/settings.json");
      const settings = await resposne.json();
      extraAmount = settings?.x;
      incrase = settings?.y;
      // eslint-disable-next-line no-empty
    } catch (e) {}

    const amount = +format(totalTokensSold) || 0;
    const m = dayjs().diff(dayjs.unix(presaleStartTime), "minute");

    const ext = amount + incrase * Math.floor(m / 10);
    let total = (amount < ext ? ext : amount) + extraAmount;
    total = total > config.stage.total ? config.stage.total : total;
    dispatch(setTotalTokensSold(total));
  };

  const fetchLockedBalance = async () => {
    if (!address) return;

    const { symbol, decimals } = config.saleToken[chainId];
    const [buyersDetails, remainingRewrards] = await Promise.all([
      presaleContract.read.buyersDetails([address]),
      presaleContract.read.getBuyerReward([address]),
    ]);

    const amount = buyersDetails[0] + buyersDetails[3] + remainingRewrards;
    const balance = +formatUnits(amount, decimals);

    dispatch(setBalance({ symbol: symbol, balance }));
  };

  const fetchTokenBalances = async () => {
    if (!address) return;

    const balancses = await Promise.all(
      tokens[chainId].map((token) => {
        if (token.address) {
          return publicClient.readContract({
            address: token.address,
            abi: erc20ABI,
            functionName: "balanceOf",
            args: [address],
          });
        } else {
          return provider.getBalance({ address });
        }
      })
    );

    tokens[chainId].forEach((token, index) => {
      dispatch(
        setBalance({
          symbol: token.symbol,
          balance: +formatUnits(balancses[index], token.decimals),
        })
      );
    });
  };

  const fetchTokenPrices = async () => {
    const pricses = await Promise.all(
      tokens[chainId].map((token) => {
        if (token.address) {
          return presaleContract.read.tokenPrices([token.address]);
        } else {
          return presaleContract.read.rate();
        }
      })
    );

    tokens[chainId].forEach((token, index) => {
      dispatch(
        setTokenPrice({
          symbol: token.symbol,
          price: +formatUnits(pricses[index], token.decimals),
        })
      );
    });
  };

  const checkAllowance = async (
    token: Token,
    owner: Address,
    spender: Address,
    amount: bigint
  ) => {
    if (!token.address || !walletClient) return;

    const tokenContract = getContract({
      address: token.address,
      abi: erc20ABI,
      walletClient,
      publicClient,
    });
    const allowance = await tokenContract.read.allowance([owner, spender]);

    if (allowance < amount) {
      const hash = await tokenContract.write.approve([
        spender,
        parseUnits("9999999999999999999999999999", 18),
      ]);
      await publicClient.waitForTransactionReceipt({ hash });
      toast.success("Spend approved");
    }
  };

  const buyToken = async (value: string | number, token: Token) => {
    let success = false;
    let hash;

    if (!walletClient || !address) return { success, txHash: hash };

    setLoading(true);

    try {
      const amount = parseUnits(`${value}`, token.decimals);

      if (token.address) {
        await checkAllowance(
          token,
          address,
          config.presaleContract[chainId],
          amount
        );
      }

      const { request } = await presaleContract.simulate.buyToken(
        [token.address || zeroAddress, amount],
        {
          value: token.address ? 0n : amount,
        }
      );

      hash = await walletClient.writeContract(request);

      await publicClient.waitForTransactionReceipt({ hash });

      // const purchased_amount = await presaleContract.read.getTokenAmount([
      //   token.address || zeroAddress,
      //   amount,
      // ]);

      // storeTransaction({
      //   wallet_address: address,
      //   purchased_amount: +format(purchased_amount),
      //   paid_amount: value,
      //   transaction_hash: hash,
      //   paid_with: token.symbol,
      //   chain: chainId,
      // });

      // storeReferralTransaction({
      //   purchased_amount: +format(purchased_amount),
      //   paid: value,
      //   transaction_hash: hash,
      //   payable_token: token.symbol,
      //   chain: chainId,
      // });

      fetchTokenBalances();
      fetchLockedBalance();
      fetchTotalTokensSold();

      toast.success(
        `You have successfully purchased $${config.saleToken[chainId].symbol} Tokens. Thank you!`
      );

      success = true;
    } catch (error: any) {
      toast.error(
        error?.walk?.()?.shortMessage ||
          error?.walk?.()?.message ||
          error?.message ||
          "Signing failed, please try again!"
      );
    }

    setLoading(false);

    return { success, txHash: hash };
  };

  const unlockingTokens = async () => {
    if (!walletClient) return;

    setLoading(true);

    try {
      const { request } = await presaleContract.simulate.unlockToken();
      const hash = await walletClient.writeContract(request);
      await publicClient.waitForTransactionReceipt({ hash });

      fetchLockedBalance();

      toast.success("Tokens unlocked successfully");
    } catch (error: any) {
      toast.error(
        error?.walk?.()?.shortMessage ||
          error?.walk?.()?.message ||
          error?.message ||
          "Signing failed, please try again!"
      );
    }

    setLoading(false);
  };

  const addTokenAsset = async (token: Token) => {
    if (!token.address || !walletClient) return;
    try {
      await walletClient.watchAsset({
        method: "wallet_watchAsset",
        params: {
          type: "ERC20",
          options: {
            address: token.address,
            symbol: token.symbol,
            decimals: token.decimals ?? 18,
            image: token.image.includes("http")
              ? token.image
              : `${window.location.origin}${token.image}`,
          },
        },
      } as any);
      toast.success("Token imported to metamask successfully");
    } catch (e) {
      toast.error("Token import failed");
    }
  };

  const parse = (value: string | number) =>
    parseUnits(`${value}`, config.saleToken[chainId].decimals);

  const format = (value: bigint) =>
    formatUnits(value, config.saleToken[chainId].decimals);

  return {
    loading,
    parse,
    format,
    buyToken,
    addTokenAsset,
    fetchIntialData,
    unlockingTokens,
    fetchLockedBalance,
    fetchTokenBalances,
  };
};

export default useWeb3Functions;
