#!/bin/zsh
cd "/Users/six.user/Documents/LUNAAPPWIN/MINHAS CONTAS"

PORT=8787
IP=$(ipconfig getifaddr en0)

if [ -z "$IP" ]; then
  IP=$(ipconfig getifaddr en1)
fi

echo ""
echo "Smart Lista rodando para o iPhone"
echo "--------------------------------"
echo ""
echo "No iPhone, abra no Safari:"
echo "http://$IP:$PORT/smart-lista.html"
echo ""
echo "Depois toque em Compartilhar > Adicionar à Tela de Início."
echo ""
echo "Deixe esta janela aberta enquanto estiver usando pelo iPhone."
echo ""

python3 -m http.server "$PORT" --bind 0.0.0.0
