import QRCode from "qrcode";
import Image from "next/image";

export async function QRCodeImage({
  value,
  size = 180,
  className,
}: {
  value: string;
  size?: number;
  className?: string;
}) {
  const dataUrl = await QRCode.toDataURL(value, {
    width: size * 2,
    margin: 1,
    color: {
      dark: "#1F2937",
      light: "#FFFFFF",
    },
  });

  return (
    <img
      src={dataUrl}
      alt="Booking QR Code"
      width={size}
      height={size}
      className={className}
    />
  );
}
