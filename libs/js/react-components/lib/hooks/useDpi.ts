import { useEffect, useState } from "react";

export function useDpi() {
  const [dpi, setDpi] = useState<number>(1);

  useEffect(() => {
    setDpi(window.devicePixelRatio);
  }, []);

  return dpi;
}
