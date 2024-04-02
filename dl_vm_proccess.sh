#!/bin/bash

# Verificar si el script se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ser ejecutado como root" >&2
    exit 1
fi

# Crear el usuario 'hadoop' si no existe
if ! id "hadoop" &>/dev/null; then
    useradd -m hadoop
    echo "Usuario 'hadoop' creado."

    # Añadir configuración del prompt al .bashrc del usuario 'hadoop'
    echo "export PS1='\u@\h:\w\$ '" >> /home/hadoop/.bashrc

    echo "Por favor, establezca la contraseña para el usuario 'hadoop':"
    passwd hadoop
else
    echo "El usuario 'hadoop' ya existe."
fi


# Crear directorio de trabajo en /opt/hadoop
mkdir -p /opt/hadoop
chown -R hadoop:hadoop /opt/hadoop
echo "Directorio /opt/hadoop preparado y permisos ajustados."

# Cambiar al usuario 'hadoop' para realizar descargas e instalaciones
# Nota: Desde un script, no se puede cambiar de usuario y continuar ejecutando el mismo script
# La descarga, descompresión e instalación de Hadoop y JDK se realizará como root,
# pero ajustaremos los permisos adecuadamente.


# Comprobamos si existe curl
if ! type -p curl; then
    echo "curl no está instalado. Instalando curl..."
    apt-get update
    apt-get install -y curl
fi

# Descargar Hadoop
echo "Descargando Hadoop..."
curl --output /opt/hadoop/hadoop.tar.gz https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz

# Descomprimir Hadoop
echo "Descomprimiendo Hadoop..."
tar -xzf /opt/hadoop/hadoop.tar.gz -C /opt/hadoop --strip-components=1
rm /opt/hadoop/hadoop.tar.gz
chown -R hadoop:hadoop /opt/hadoop

# Verificar e instalar JDK (Ejemplo con OpenJDK 11)
echo "Verificando JDK..."
if type -p java; then
    echo "JDK ya está instalado."
else
    echo "Instalando OpenJDK 11..."
    apt-get update
    apt-get install -y openjdk-11-jdk
fi

# Configurar variables de entorno para el usuario 'hadoop'
echo "Configurando variables de entorno..."
cat >> /home/hadoop/.bashrc <<EOF

# Java configuration
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

# Hadoop configuration
export HADOOP_HOME=/opt/hadoop
export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF


cat > /etc/profile.d/hadoop.sh <<EOF
# Java configuration
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")

# Hadoop configuration
export HADOOP_HOME=/opt/hadoop
export PATH=\$PATH:\$JAVA_HOME/bin:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
EOF


# Notificar al usuario sobre la necesidad de cambiar a 'hadoop' para verificar la instalación
echo "Instalación completada. Por favor, cambie al usuario 'hadoop' (su hadoop) y ejecute '. ~/.bashrc' para actualizar las variables de entorno."
echo "Puede verificar la instalación de Hadoop ejecutando 'hadoop version' y la de Java con 'java -version'."

