import { write } from "@denota-labs/denota-sdk";
import { useCallback } from "react";
import { NotaCurrency } from "../../components/designSystem/CurrencyIcon";
import { useBlockchainData } from "../../context/BlockchainDataProvider";

interface Props {
  dueDate?: string;
  token: NotaCurrency;
  amount: string;
  address: string;
  externalURI: string;
  imageURI: string;
}

export const useSimpleCash = () => {
  const { blockchainState } = useBlockchainData();

  const writeNota = useCallback(
    async ({
      token,
      amount,
      address,
      externalURI,
      imageURI,
    }: Props) => {
      if (token === "UNKNOWN") {
        return;
      }
      const receipt = await write({
        currency: token,
        amount: Number(amount),
        instant: 0,
        owner: address,
        moduleName: "simpleCash",
        metadata: { type: "uploaded", externalURI, imageURI },
      });
      return receipt;
    },
    [blockchainState.account]
  );

  return { writeNota };
};
