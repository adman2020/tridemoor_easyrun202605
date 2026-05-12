# Register 16 accounts 13800000101-116 with password 123456
$hash = '$2b$10$Rrrd9WGndMNu1NH9aqnDw.sH4QMSe7/NBgdQPxw/BNY17CkQ88xXC'
$sql = "INSERT IGNORE INTO users (id, nickname, phone, password_hash, gender) VALUES`n"
$nicknames = @(
    "跑者01","跑者02","跑者03","跑者04","跑者05",
    "跑者06","跑者07","跑者08","跑者09","跑者10",
    "跑者11","跑者12","跑者13","跑者14","跑者15","跑者16"
)
$values = @()
for ($i = 0; $i -lt 16; $i++) {
    $phone = "1380000010" + ($i + 1).ToString("D2")
    $uuid = [guid]::NewGuid().ToString()
    $values += "('$uuid','$($nicknames[$i])','$phone','$hash',1)"
}
$sql += ($values -join ",`n") + ";"
$sql | mysql -h 127.0.0.1 -P 3306 -u stridemoor -pstridemoor_pass_2026 stridemoor 2>&1

Write-Host "注册完成，验证一下："
mysql -h 127.0.0.1 -P 3306 -u stridemoor -pstridemoor_pass_2026 stridemoor -e "SELECT phone, nickname FROM users WHERE phone LIKE '138000001%'" 2>&1
