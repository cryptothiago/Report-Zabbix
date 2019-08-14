### Arquivos de configuração globais, aplicados a todos os usuários:

- **/etc/profile**: Arquivo de inicialização executado durante o processo de login de todos os usuários do sistema. Em caso de processo de login, será sempre o primeiro arquivo executado.
- **/etc/profile.d/**: Todos os scripts presentes nesse diretório serão executados durante o processo de login de cada usuário do sistema.
- **/etc/bash.bashrc**: Arquivo executado para toda nova sessão de shell bash, aplicado a todos os usuários. 
- **/etc/inputrc**: Arquivo global utilizado para customização de opções do teclado e de comportamento do terminal.
- **/etc/skel/**: Todos os arquivos e diretórios presentes nesse diretório serão incluídos no diretório home de novos usuários criados no sistema.

### Arquivos de configuração locais, de cada usuário:

- **~/.bash_profile**: Se existir, o arquivo é executado após o /etc/profile, durante o processo de login do usuário.
- **~/.bash_login**: Se .bash_profile não existir, o arquivo é executado automaticamente durante o processo de login, após a execução do /etc/profile.
- **~/.profile**: Não existindo .bash_profile e .bash_login, o arquivo é executado durante o login após a execução do /etc/profile.
- **~/.bashrc**: Executado automaticamente em toda nova sessão de shell bash, logo após o /etc/bash.bashrc.
- **~/.inputrc**: Implemente a nível de usuário vinculações de teclas e opções referentes ao terminal
- **~/.bash_logout**: Arquivo executado durante o processo de logout do usuário

**OBS As configurações globais são sempre executadas primeiro que as configurações locais. O que significa também que as locais podem "sobrescrever" as globais.**

## CHSH

#### O chsh serve simplesmente para alterar o shell utilizado pelo usuário. Por exemplo:

`$ chsh
Senha:
Mudando o shell de login para ricardo
Informe o novo valor ou pressione ENTER para aceitar o padrão
    Shell de Login [/bin/sh]: /bin/bash`

## TEST

#### O comando test possui uma série de opções para comparação de valores e strings.

#### Dentro de um script, há 2 formas de sintaxe possíveis:

test expressão

*Exemplo:* `test -f /etc/profile`

ou 

[ expressão ]

*Exemplo:* `[ -f /etc/profile ]`

As principais opções utilizadas são:

Tab

### Análises de Arquivos e Diretórios

- **-f Arquivo**: Verifica se o arquivo indicado existe e é um arquivo regular
- **-r Arquivo**: Verificar se há permissão de leitura
- **-w Arquivo**: Verificar se há permissão de escrita
- **-x Arquivo**: Verificar se há permissão de execução
- **-s Arquivo**: Verifica se o tamanho do arquivo é maior que 0
- **-o Arquivo**: Executa um ou outro
- **-d Diretório**: Verifica se o caminho indicado é um diretório existente`


### Comparação de Strings

- **-n $VAR1**: Usado com variáveis, verifica se o tamanho do conteúdo da variável é diferente de zero (nonzero)
- **-z $VAR1**: Usado com variáveis, verifica se o tamanho do conteúdo da variável é zero
- **$VAR1**: Usado com variáveis, indica verdadeiro se $VAR1 não for nulo
- **String1 = String2**: Compara se as duas strings são iguais
- **String1 != String2**: Verifica se as duas strings são diferentes



### Comparação de Valores Numéricos

- **Valor1 -eq Valor2**: Verdadeiro se os 2 valores forem iguais (equal)
- **Valor1 -ne Valor2**: Verdadeiro se os 2 valores forem diferentes (not equal)
- **Valor1 -gt Valor2**: Verdadeiro se o Valor1 for maior que Valor2 (greater than)
- **Valor1 -ge Valor2**: Verdadeiro se o Valor1 for maior ou igual que Valor2 (greater or equal)
- **Valor1 -lt Valor2**: Verdadeiro se o Valor1 for menor que Valor2 (less than)
- **Valor1 -le Valor2**: Verdadeiro se o Valor1 for menor ou igual que Valor2 (less or equal)



### Negação

- **!**: A presença da exclamação indica a negação da expressão a seguir
