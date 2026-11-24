<?php

$projects = [
    [
        'name' => 'Datatem',
        'category' => 'Data & wallet',
        'summary' => 'Data bundles, wallet top-ups, digital services and a reseller network in one customer account.',
        'stack' => ['Laravel 11', 'MySQL', 'Paystack'],
        'demo' => 'http://datatem.test',
        'note' => 'Local demo',
    ],
    [
        'name' => 'Novagel Imports',
        'category' => 'Commerce',
        'summary' => 'A guest storefront with cart, Paystack checkout, order tracking and a separate administrator back office.',
        'stack' => ['Laravel 13', 'MySQL', 'Paystack'],
        'demo' => null,
        'note' => 'Local setup in progress',
    ],
    [
        'name' => 'AFA Ghana',
        'category' => 'Public service',
        'summary' => 'Farmer registration and AFA service workflows with a focused customer support path.',
        'stack' => ['Laravel', 'SQLite', 'WhatsApp'],
        'demo' => 'http://AFA-GHANA.test',
        'note' => 'Local demo',
    ],
    [
        'name' => 'PATU Technologies',
        'category' => 'AI & research',
        'summary' => 'An AI research and engineering suite spanning backend services, design intelligence, voice and social automation.',
        'stack' => ['Laravel', 'Python', 'Redis'],
        'demo' => null,
        'note' => 'Local stack setup in progress',
    ],
    [
        'name' => 'PATUchat',
        'category' => 'AI workspace',
        'summary' => 'A chat workspace for working with AI models in a focused, account-based interface.',
        'stack' => ['Laravel', 'SQLite', 'AI'],
        'demo' => 'http://PATUchat.test',
        'note' => 'Local demo',
    ],
    [
        'name' => 'Patupa',
        'category' => 'Digital services',
        'summary' => 'A digital services and payments platform with reseller operations and wallet flows.',
        'stack' => ['Laravel', 'MySQL', 'Payments'],
        'demo' => 'http://patupa.test',
        'note' => 'Local demo',
    ],
    [
        'name' => 'Patutrade',
        'category' => 'Trading systems',
        'summary' => 'Trading automation and market tools with strategy workflows and operational controls.',
        'stack' => ['Laravel', 'MySQL', 'Market data'],
        'demo' => 'http://patutrade.worktrees.test',
        'note' => 'Local demo',
    ],
];

$projectCount = count($projects);

?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="light">
    <title>Template Business — Working systems</title>
    <meta name="description" content="A working library of digital systems built in Ghana: data, commerce, public services, AI and trading.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,500;12..96,600;12..96,700&family=Public+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --ink: #0b2b33;
            --paper: #f3efe4;
            --paper-deep: #e9e2d2;
            --gold: #d7a33d;
            --teal: #2f6f63;
            --muted: #62726d;
            --line: #d7cfbf;
        }

        * {
            box-sizing: border-box;
        }

        html {
            scroll-behavior: smooth;
        }

        body {
            margin: 0;
            background: var(--paper);
            color: var(--ink);
            font-family: "Public Sans", ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            line-height: 1.55;
            -webkit-font-smoothing: antialiased;
        }

        a {
            color: inherit;
        }

        .skip-link {
            position: absolute;
            top: -100px;
            left: 16px;
            z-index: 10;
            background: var(--gold);
            color: var(--ink);
            padding: 10px 14px;
            font-weight: 700;
            text-decoration: none;
        }

        .skip-link:focus {
            top: 16px;
        }

        .shell {
            width: min(1240px, calc(100% - 2 * clamp(20px, 4vw, 56px)));
            margin-inline: auto;
        }

        .hero {
            position: relative;
            overflow: hidden;
            background: var(--ink);
            color: var(--paper);
        }

        .hero::after {
            content: "";
            position: absolute;
            inset: 0;
            pointer-events: none;
            background-image:
                linear-gradient(rgba(243, 239, 228, 0.045) 1px, transparent 1px),
                linear-gradient(90deg, rgba(243, 239, 228, 0.045) 1px, transparent 1px);
            background-size: 56px 56px;
        }

        .hero .shell {
            position: relative;
            z-index: 1;
        }

        .topbar {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 24px;
            padding: 26px 0 22px;
            border-bottom: 1px solid rgba(243, 239, 228, 0.18);
        }

        .brand {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            font-size: 15px;
            font-weight: 700;
            letter-spacing: -0.01em;
            text-decoration: none;
        }

        .brand-mark {
            display: block;
            width: 14px;
            height: 14px;
            background: var(--gold);
        }

        .topbar-note {
            margin: 0;
            color: #aebdb7;
            font-size: 12px;
            line-height: 1.5;
            text-align: right;
        }

        .hero-grid {
            display: grid;
            grid-template-columns: minmax(0, 1.45fr) minmax(240px, 0.55fr);
            gap: clamp(32px, 6vw, 96px);
            align-items: end;
            padding: clamp(56px, 9vw, 112px) 0 clamp(48px, 7vw, 80px);
        }

        h1 {
            margin: 0 0 28px;
            font-family: "Bricolage Grotesque", ui-sans-serif, system-ui, sans-serif;
            font-size: clamp(54px, 9vw, 112px);
            font-weight: 600;
            line-height: 0.88;
            letter-spacing: -0.065em;
        }

        .hero-copy {
            max-width: 44ch;
            margin: 0;
            color: #c8d3ce;
            font-size: clamp(16px, 1.35vw, 19px);
            line-height: 1.55;
        }

        .hero-aside {
            border-top: 1px solid rgba(243, 239, 228, 0.25);
            padding-top: 18px;
        }

        .hero-aside > p {
            margin: 0 0 24px;
            color: #c8d3ce;
            font-size: 14px;
            line-height: 1.55;
        }

        .hero-aside dl {
            display: grid;
            gap: 10px;
            margin: 0;
        }

        .hero-aside dl div {
            display: flex;
            justify-content: space-between;
            gap: 16px;
            border-bottom: 1px solid rgba(243, 239, 228, 0.12);
            padding-bottom: 8px;
        }

        .hero-aside dt {
            color: #98aaa3;
            font-size: 12px;
        }

        .hero-aside dd {
            margin: 0;
            color: var(--gold);
            font-size: 12px;
            font-weight: 600;
        }

        .library {
            padding: clamp(56px, 8vw, 96px) 0 clamp(56px, 7vw, 88px);
        }

        .section-head {
            display: flex;
            align-items: baseline;
            justify-content: space-between;
            gap: 24px;
            padding-bottom: 22px;
        }

        .section-head h2 {
            margin: 0;
            font-family: "Bricolage Grotesque", ui-sans-serif, system-ui, sans-serif;
            font-size: clamp(30px, 3.2vw, 44px);
            font-weight: 600;
            letter-spacing: -0.04em;
            line-height: 1;
        }

        .section-head p {
            margin: 0;
            color: var(--muted);
            font-size: 14px;
        }

        .project-grid {
            border-top: 1px solid var(--line);
        }

        .project {
            display: grid;
            grid-template-columns: minmax(0, 0.9fr) minmax(0, 1.1fr);
            gap: clamp(24px, 5vw, 80px);
            padding: clamp(26px, 4vw, 40px) clamp(0px, 1vw, 16px);
            border-bottom: 1px solid var(--line);
            transition: background-color 180ms ease;
        }

        .project:hover {
            background: var(--paper-deep);
        }

        .category {
            display: flex;
            align-items: center;
            gap: 8px;
            margin: 0 0 12px;
            color: var(--teal);
            font-size: 12px;
            font-weight: 600;
            letter-spacing: 0.02em;
        }

        .category::before {
            content: "";
            flex: none;
            width: 6px;
            height: 6px;
            background: var(--gold);
        }

        .project-name {
            margin: 0;
            font-family: "Bricolage Grotesque", ui-sans-serif, system-ui, sans-serif;
            font-size: clamp(30px, 3.25vw, 44px);
            font-weight: 600;
            letter-spacing: -0.045em;
            line-height: 1;
        }

        .project-name a {
            text-decoration: none;
            transition: color 180ms ease;
        }

        .project-name a:hover {
            color: var(--teal);
        }

        .project-note {
            margin: 10px 0 0;
            color: var(--muted);
            font-size: 11px;
        }

        .project-body {
            display: flex;
            flex-direction: column;
            align-items: flex-start;
            gap: 16px;
        }

        .summary {
            max-width: 56ch;
            margin: 0;
            color: #344a4d;
            font-size: 15px;
            line-height: 1.6;
        }

        .stack {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin: 0;
            padding: 0;
            list-style: none;
        }

        .stack li {
            border: 1px solid var(--line);
            background: rgba(255, 255, 255, 0.25);
            color: var(--muted);
            font-size: 11px;
            line-height: 1.25;
            padding: 3px 8px 4px;
        }

        .demo {
            display: inline-block;
            margin-top: 2px;
            border-bottom: 2px solid var(--gold);
            padding-bottom: 2px;
            font-size: 13px;
            font-weight: 700;
            text-decoration: none;
            transition: color 180ms ease, border-color 180ms ease;
        }

        .demo:hover {
            color: var(--teal);
            border-color: var(--teal);
        }

        .demo-pending {
            margin-top: 2px;
            color: var(--muted);
            font-size: 12px;
            font-style: italic;
        }

        .site-footer {
            border-top: 1px solid var(--line);
            padding: 24px 0 36px;
        }

        .footer-inner {
            display: flex;
            justify-content: space-between;
            gap: 18px;
            flex-wrap: wrap;
            color: var(--muted);
            font-size: 12px;
        }

        .footer-inner p {
            margin: 0;
        }

        .footer-inner strong {
            color: var(--ink);
        }

        :focus-visible {
            outline: 2px solid var(--gold);
            outline-offset: 4px;
        }

        ::selection {
            background: var(--gold);
            color: var(--ink);
        }

        @media (max-width: 760px) {
            .hero-grid {
                grid-template-columns: 1fr;
                padding-top: 48px;
            }

            .hero-aside {
                max-width: 420px;
            }

            .topbar-note {
                display: none;
            }

            .project {
                grid-template-columns: 1fr;
                gap: 18px;
                padding-inline: 0;
            }

            .section-head {
                display: block;
            }

            .section-head p {
                margin-top: 8px;
            }

            .footer-inner {
                display: block;
            }

            .footer-inner p + p {
                margin-top: 6px;
            }
        }

        @media (prefers-reduced-motion: reduce) {
            html {
                scroll-behavior: auto;
            }

            * {
                transition: none !important;
            }
        }
    </style>
</head>
<body>
    <a class="skip-link" href="#projects">Skip to projects</a>

    <header class="hero">
        <div class="shell">
            <div class="topbar">
                <a class="brand" href="/">
                    <span class="brand-mark" aria-hidden="true"></span>
                    <span>Template Business</span>
                </a>
                <p class="topbar-note">Working library<br>Ghana, 2026</p>
            </div>

            <div class="hero-grid">
                <div>
                    <h1>A working<br>library.</h1>
                    <p class="hero-copy">Seven systems for data, commerce, public services, AI and trading. Built in Ghana, each one a complete deployment ready to adapt.</p>
                </div>
                <aside class="hero-aside" aria-label="Library summary">
                    <p>Seven projects. One standard: the build has to work.</p>
                    <dl>
                        <div>
                            <dt>Projects</dt>
                            <dd><?= $projectCount ?></dd>
                        </div>
                        <div>
                            <dt>Local demos</dt>
                            <dd>Laragon</dd>
                        </div>
                    </dl>
                </aside>
            </div>
        </div>
    </header>

    <main id="projects" class="library">
        <div class="shell">
            <div class="section-head">
                <h2>The projects</h2>
                <p>Separate deployments. Shared standard.</p>
            </div>

            <div class="project-grid">
                <?php foreach ($projects as $project): ?>
                    <article class="project">
                        <div>
                            <p class="category"><?= htmlspecialchars($project['category'], ENT_QUOTES, 'UTF-8') ?></p>
                            <?php if ($project['demo']): ?>
                                <h3 class="project-name">
                                    <a href="<?= htmlspecialchars($project['demo'], ENT_QUOTES, 'UTF-8') ?>" target="_blank" rel="noopener"><?= htmlspecialchars($project['name'], ENT_QUOTES, 'UTF-8') ?></a>
                                </h3>
                            <?php else: ?>
                                <h3 class="project-name"><?= htmlspecialchars($project['name'], ENT_QUOTES, 'UTF-8') ?></h3>
                            <?php endif; ?>
                            <p class="project-note"><?= htmlspecialchars($project['note'], ENT_QUOTES, 'UTF-8') ?></p>
                        </div>

                        <div class="project-body">
                            <p class="summary"><?= htmlspecialchars($project['summary'], ENT_QUOTES, 'UTF-8') ?></p>
                            <ul class="stack" aria-label="Technology stack">
                                <?php foreach ($project['stack'] as $item): ?>
                                    <li><?= htmlspecialchars($item, ENT_QUOTES, 'UTF-8') ?></li>
                                <?php endforeach; ?>
                            </ul>
                            <?php if ($project['demo']): ?>
                                <a class="demo" href="<?= htmlspecialchars($project['demo'], ENT_QUOTES, 'UTF-8') ?>" target="_blank" rel="noopener">Open demo</a>
                            <?php else: ?>
                                <span class="demo-pending">Demo in setup</span>
                            <?php endif; ?>
                        </div>
                    </article>
                <?php endforeach; ?>
            </div>
        </div>
    </main>

    <footer class="site-footer">
        <div class="shell footer-inner">
            <p><strong>Template Business</strong> — built in Ghana.</p>
            <p>Available for licensing and deployment.</p>
        </div>
    </footer>
</body>
</html>
