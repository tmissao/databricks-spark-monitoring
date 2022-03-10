package br.com.missao.samplejob

import com.microsoft.pnp.util.TryWith
import com.microsoft.pnp.logging.Log4jConfiguration
import org.slf4j.LoggerFactory

object LogSampleJob {
  def main(args: Array[String]): Unit = {

    // Configuring Logging from log4j.properties file
    TryWith(getClass.getResourceAsStream("/br/com/missao/samplejob/log4j.properties")) {
      stream => {
        Log4jConfiguration.configure(stream)
      }
    }

    val logger = LoggerFactory.getLogger(getClass.getName)

    logger.trace("LogSampleJob - Trace Message")
    logger.debug("LogSampleJob - Debug Message")
    logger.info("LogSampleJob - Info Message")
    logger.warn("LogSampleJob - Warning Message")
    logger.error("LogSampleJob - Error Message")

    logger.info("That is all fellas!")
  }
}