$w = Invoke-WebRequest -Uri "https://www.amazon.com/dp/B01KGFR3OO/ref=twister_B000N5Z2L4?_encoding=UTF8&psc=1"
$w.Content | Out-File test.html