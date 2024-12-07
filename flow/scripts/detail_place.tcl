utl::set_metrics_stage "detailedplace__{}"
source $::env(SCRIPTS_DIR)/load.tcl
erase_non_stage_variables place
load_design 3_4_place_resized.odb 2_floorplan.sdc

source $::env(PLATFORM_DIR)/setRC.tcl


proc run_detailed_placement {max_displacement} {
    if {$max_displacement eq ""} {
        set command "detailed_placement"
        try {
        detailed_placement
        puts "Command succeeded: $command"
        return 0
    } on error {errMsg} {
        puts "Command failed: $command"
        puts "Error message: $errMsg"
        return 1
    }



    } else {
        set command "detailed_placement -max_displacement $max_displacement"
    }

    

    puts "Running: detailed_placement -max_displacement $max_displacement"
    try {
        detailed_placement -max_displacement $max_displacement
        puts "Command succeeded: $command"
        return 0
    } on error {errMsg} {
        puts "Command failed: $command"
        puts "Error message: $errMsg"
        return 1
    }
}





proc do_dpl {} {
  # Only for use with hybrid rows
  if {[env_var_equals BALANCE_ROWS 1]} {
    balance_row_usage
  }
  
  set_placement_padding -global \
      -left $::env(CELL_PAD_IN_SITES_DETAIL_PLACEMENT) \
      -right $::env(CELL_PAD_IN_SITES_DETAIL_PLACEMENT)

  # detailed_placement
  set success [run_detailed_placement ""]


  if {$success} {
      set max_displacement_values {50 100 500 1000 5000 10000 50000 100000 500000 1000000}
      foreach max_displacement $max_displacement_values {
          set success [run_detailed_placement $max_displacement]
          if {!$success} {
              break
          }
      }
  }

  if {$success} {
      puts "All attempts failed."
  } else {
      puts "Placement succeeded."
  }

  
  if {[env_var_equals ENABLE_DPO 1]} {
    if {[env_var_exists_and_non_empty DPO_MAX_DISPLACEMENT]} {
      improve_placement -max_displacement $::env(DPO_MAX_DISPLACEMENT)
    } else {
      improve_placement
    }
  }
  optimize_mirroring

  utl::info FLW 12 "Placement violations [check_placement -verbose]."
  
  estimate_parasitics -placement
}

set result [catch {do_dpl} errMsg]
if {$result != 0} {
  write_db $::env(RESULTS_DIR)/3_5_place_dp-failed.odb
  error $errMsg
}

report_metrics 3 "detailed place" true false

write_db $::env(RESULTS_DIR)/3_5_place_dp.odb
