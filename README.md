# Atividade prática de representação do mundo de um jogo simples

Temos um jogo feito em Godot, onde o mapa tem 9 áreas (um grid 3x3), com inimigos, medkits e munição espalhados pelo mapa. Somente as áreas que o jogador está perto são ativas, ou seja, os inimigos 'existem' e se movem somente quando o jogador está perto; caso contrário, tudo naquela área é liberado da memória.

## Como jogar

- **Navegador:** https://novadrake76.github.io/ia-att-one/
- **Windows:** [ia-att-one-windows.zip](https://github.com/NovaDrake76/ia-att-one/releases/latest/download/ia-att-one-windows.zip)

| Tecla | Ação |
|---|---|
| WASD ou setas | Mover |
| Q | Usar medkit |
| Espaço | Atirar |
| Scroll do mouse | Zoom in ou out |
| R | Reiniciar |
| Esc | Voltar ao menu |

## Como funciona

**As áreas ficam em um array.** O mundo é `grid[row][col]`, um array 3x3. Cada célula é um objeto `Area`, com o retângulo da área, uma lista de inimigos e uma lista de itens. Para saber em qual área uma posição está, basta dividir a posição pelo tamanho da área, sem precisar procurar.

**No máximo 4 áreas ativas.** A área onde o jogador está sempre fica ativa. Quando ele chega perto de uma borda (a *distância de ativação*), a área vizinha daquele lado também é ativada; perto de um canto, a diagonal também. Como o código escolhe no máximo um vizinho na horizontal e um na vertical, nunca passa de 4. A linha fina dentro da área atual mostra esse limite.

**Áreas inativas são liberadas da memória, não só congeladas.** Quando uma área deixa de ser ativa, ela é salva em um arquivo JSON e sua célula no array vira `null`, então o Godot apaga a área com seus inimigos e itens. Quando o jogador volta, a área é lida do arquivo e reconstruída do jeito que estava. Por isso as áreas inativas aparecem escuras e vazias. A cada frame, só os inimigos das áreas ativas são atualizados.

**Os inimigos perseguem o jogador em linha reta.** A cada frame, cada inimigo de uma área ativa anda direto até o jogador e, enquanto encosta nele, tira vida. Quando um inimigo passa para outra área, ele é movido para a lista dela.

**A câmera não depende do grid.** Ela segue o jogador, então a tela pode mostrar partes de até 4 áreas ao mesmo tempo.

**Itens e morte.** O medkit recupera vida, e a munição causa dano em todos os inimigos num raio em volta do jogador. Quem fica com vida 0 ou menos morre: o inimigo é removido e, se for o jogador, é fim de jogo.

**O estado inicial vem de arquivos JSON.** Cada arquivo em `scenarios/` define o tamanho das áreas, a distância de ativação, a quantidade de inimigos e itens, o dano e o tempo de sobrevivência. As posições são sorteadas com a seed do arquivo, então o mesmo cenário sempre gera o mesmo mapa (e nenhum inimigo nasce perto do ponto inicial).

## Código

| Arquivo | Conteúdo |
|---|---|
| `scripts/world.gd` | O grid, a ativação das áreas, salvar e carregar áreas, o loop do jogo e o desenho |
| `scripts/area.gd` | Uma área: seus inimigos e itens, e a conversão de/para JSON |
| `scripts/enemy.gd` | Dados do inimigo e a perseguição |
| `scripts/item.gd` | Dados do medkit e da munição |
| `scripts/player.gd` | Movimento, vida, inventário e zoom da câmera |
| `scripts/hud.gd` | Painel de informações e menu de cenários |
