import { ethereumClient } from "./utils/wagmi";
import { Web3Modal } from "@web3modal/react";
import { ReferralModalTarget } from "./components/ReferralModal";
import { fetchReferralCode } from "./utils/apis";
import { useAccount } from "wagmi";
import { useDispatch } from "react-redux";
import HeaderSection from "./components/sections/HeaderSection";
import { useEffect } from "react";
import config from "./config";
import { setUser } from "./store/wallet";

const projectId = import.meta.env.VITE_WALLET_CONNECT_PROJECT_ID;

function App() {
  const { address, isConnected } = useAccount();
  const dispatch = useDispatch();

  useEffect(() => {
    const searchParams = new URLSearchParams(window?.location.search);
    const referralId = searchParams.get("ref");
    if (referralId?.length === 6) {
      localStorage.setItem("ref", referralId);
    }
  }, []);

  useEffect(() => {
    if (!isConnected) return;

    signIn();
  }, [isConnected]);

  const signIn = async () => {
    try {
      const { user } = await fetchReferralCode(address as string);
      dispatch(setUser({ ...user }));
    } catch (e) {
      console.log(e);
    }
  };
  useEffect(() => {
    let newEvent: any;

    window.addEventListener("mousemove", (event: any) => {
      newEvent = new event.constructor(event.type, event);
    });

    document.addEventListener("mousemove", (event: any) => {
      if (event.isTrusted && newEvent) {
        document.getElementById("webgl-fluid")?.dispatchEvent(newEvent);
      }
    });
  }, []);

  return (
    <>
      <main id="main" className="flex min-h-screen flex-col">
        <HeaderSection />
        <ReferralModalTarget />
      </main>
      <Web3Modal
        projectId={projectId}
        ethereumClient={ethereumClient}
        defaultChain={config.chains[0]}
      />
      {/* <WebglFluidAnimation /> */}
    </>
  );
}

export default App;
