<?php
$hardcoded = [
    ['href' => './cppreference/en/', 'text' => 'cppreference[en]'],
    ['href' => './cppreference/zh/', 'text' => 'cppreference[zh_CN]'],
    ['href' => './cppreference/', 'text' => 'search in cppreference'],
];

$existing_paths = [];
foreach ($hardcoded as $item) {
    if (preg_match('#^\./([^/]+)#', $item['href'], $matches)) {
        $existing_paths[] = $matches[1];
    }
}

$dirs = @glob('*', GLOB_ONLYDIR);
if ($dirs) {
    foreach ($dirs as $d) {
        if (substr($d, 0, 1) !== '.' && !in_array($d, $existing_paths)) {
            $hardcoded[] = ['href' => './' . $d . '/', 'text' => $d];
        }
    }
}
?>
<!DOCTYPE html>
<html>

<head>
    <title>handyMini</title>
    <style>
        html {
            font-family: monospace, consolas
        }

        body {
            font-family: "Microsoft Yahei", consolas, "Noto Sans", sans, monospace
        }

        h1 {
            max-height: 33%;
            text-align: center
        }

        .list {
            text-align: center;
            font-size: 1.4em;
            font-family: monospace;
            display: flex;
            flex-wrap: wrap
        }

        .list div {
            width: 48%;
            display: block;
            margin: 5px;
            border-radius: 10px;
            background-color: rgba(255, 255, 255, .3);
            flex: 1 0 40%;
            max-width: calc(50% - 10px);
            box-sizing: border-box;
            transition: all .3s
        }

        .list div:hover {
            background: rgba(229, 243, 243, .6);
            font-weight: 700
        }

        .list div a {
            display: block;
            height: 2em;
            line-height: 3em;
            text-decoration: none
        }

        .div-bottom a {
            display: inline-block;
            padding: 1em;
            text-decoration: none
        }

        .div-bottom {
            position: absolute;
            bottom: 0;
            width: 95%
        }
    </style>
</head>

<body>
    <h1>Index Page</h1>
    <div class="list">
<?php foreach ($hardcoded as $item): ?>
        <div><a href="<?php echo htmlspecialchars($item['href']); ?>" target="_blank"><?php echo htmlspecialchars($item['text']); ?></a><br></div>
<?php endforeach; ?>
    </div><br>
    <div class="div-bottom">
        <center class="yiyan">
            <div style="font-size:1.3em;font-weight:700"><span style="border-radius:.5em;padding:.66em" id="hitokoto"><a
                        id="hitokoto_text"></a></span></div>
        </center>
    </div>
    <script type="text/javascript">fetch('https://v1.hitokoto.cn')
            .then(response => response.json())
            .then(data => {
                const hitokoto = document.querySelector('#hitokoto_text');
                if (data["from_who"] === null || data.from === data.from_who)
                    hitokoto.innerText = data.hitokoto + " ——— " + "「" + data.from + "」";
                else
                    hitokoto.innerText = data.hitokoto + " ——— " + data.from_who + "「" + data.from + "」";
            })
            .catch(console.error);
        const gradients = [
            ['#a18cd1', '#fbc2eb'], ['#fff1eb', '#ace0f9'], ['#d4fc79', '#96e6a1'], ['#a1c4fd', '#c2e9fb'],
            ['#a8edea', '#fed6e3'], ['#9890e3', '#b1f4cf'], ['#a1c4fd', '#c2e9fb'], ['#fff1eb', '#ace0f9']
        ];
        const index = Math.floor(Math.random() * gradients.length);
        document.body.style.backgroundImage = 'linear-gradient(90deg, ' + gradients[index][0] + ', ' + gradients[index][1] + ')';
    </script>
</body>

</html>
