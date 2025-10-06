import axios from "axios";

export const storeTransaction = async (payload: any) => {
  await axios.post(`https://adminref.vultor.io/api/transaction`, payload, {
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
  });
};

export const fetchReferralCode = async (address: string) => {
  const response = await axios.get(
    `https://adminref.vultor.io/api/get-referral?address=${address}`
    
  );

  return response.data;
  console.log(response.data)
};

export const fetchBalance = async (address: string) => {
  const response = await axios.get(
    `https://adminref.vultor.io/api/${address}/balance`
  );

  return response.data?.data;
 
};

export const storeReferralTransaction = async (payload: any) => {
  const referralId = localStorage.getItem("ref");
  if (referralId?.length === 6) {
    await axios.post(
      `https://adminref.vultor.io/api/referral-transaction`,
      { ...payload, ref_address: referralId },
      {
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
      }
    );
    localStorage.removeItem("ref");
  }
};
