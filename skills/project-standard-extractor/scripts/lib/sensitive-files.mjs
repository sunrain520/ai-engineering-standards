export function isSensitivePath(file) {
  return /(^|\/)(\.env|id_rsa|id_dsa|.*\.pem|.*\.key)$/i.test(file);
}
