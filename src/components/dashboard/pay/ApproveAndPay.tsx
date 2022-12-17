import { Box, Text } from "@chakra-ui/react";
import { BigNumber } from "ethers";
import { useCallback, useEffect, useMemo, useState } from "react";
import { useBlockchainData } from "../../../context/BlockchainDataProvider";
import { Cheq } from "../../../hooks/useCheqs";
import RoundedBox from "../../designSystem/RoundedBox";
import RoundedButton from "../../designSystem/RoundedButton";

interface Props {
  cheq: Cheq;
}

function ApproveAndPay({ cheq }: Props) {
  const { blockchainState } = useBlockchainData();

  const [needsApproval, setNeedsApproval] = useState(true);

  // TODO: Handle all tokens correctly
  const token =
    cheq.token == "DAI" ? blockchainState.dai : blockchainState.weth;

  useEffect(() => {
    const fetchAllowance = async () => {
      const tokenAllowance = await token?.functions.allowance(
        blockchainState.account,
        blockchainState.cheqAddress
      );
      if (cheq.amountRaw.sub(tokenAllowance[0]) > BigNumber.from(0)) {
        setNeedsApproval(true);
      } else {
        setNeedsApproval(false);
      }
    };
    fetchAllowance();
  }, [
    blockchainState.account,
    blockchainState.cheqAddress,
    cheq.amountRaw,
    token?.functions,
  ]);

  const buttonText = useMemo(() => {
    if (needsApproval) {
      return "Approve " + cheq.token;
    }
    return "Pay";
  }, [cheq.token, needsApproval]);

  const handlePay = useCallback(async () => {
    if (needsApproval) {
      // Disabling infinite approvals until audit it complete
      // To enable:
      // BigNumber.from(
      //   "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"
      // );
      const tx = await token?.functions.approve(
        blockchainState.cheqAddress,
        cheq.amountRaw
      );
      await tx.wait();
      setNeedsApproval(false);
      // TODO: handle loading state
    } else {
      const cheqId = Number(cheq.id);
      const tx = await blockchainState.selfSignBroker?.fundCheq(
        cheqId,
        cheq.amountRaw
      );
      await tx.wait();
    }
  }, [
    blockchainState.cheqAddress,
    blockchainState.selfSignBroker,
    cheq.amountRaw,
    cheq.id,
    needsApproval,
    token?.functions,
  ]);

  return (
    <Box w="100%" p={4}>
      <RoundedBox mt={8} p={6}>
        <Text fontWeight={600} fontSize={"xl"} textAlign="center">
          {"You have 30 days to request a refund"}
        </Text>
      </RoundedBox>
      <RoundedButton onClick={handlePay}>{buttonText}</RoundedButton>
    </Box>
  );
}

export default ApproveAndPay;
